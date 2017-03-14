/* surrounding with S-Lang functions, this is actually the main
  function from examples/decoder_example.c with the comments intact
*/

/********************************************************************
 *                                                                  *
 * THIS FILE IS PART OF THE OggVorbis SOFTWARE CODEC SOURCE CODE.   *
 * USE, DISTRIBUTION AND REPRODUCTION OF THIS LIBRARY SOURCE IS     *
 * GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
 * IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
 *                                                                  *
 * THE OggVorbis SOURCE CODE IS (C) COPYRIGHT 1994-2009             *
 * by the Xiph.Org Foundation http://www.xiph.org/                  *
 *                                                                  *
 ********************************************************************
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <math.h>
#include <vorbis/codec.h>
#include <ogg/ogg.h>
#include <slang.h>

SLANG_MODULE(vorbis);

typedef struct
  {
  int verbose;
  char *comments;
  char *msg;
  } Vorbis_Type;

SLang_CStruct_Field_Type Vorbis_Type_Layout [] =
  {
  MAKE_CSTRUCT_INT_FIELD(Vorbis_Type, verbose, "verbose", 0),
  MAKE_CSTRUCT_FIELD(Vorbis_Type, msg, "msg", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD(Vorbis_Type, comments, "comments", SLANG_STRING_TYPE, 0),

  SLANG_END_CSTRUCT_TABLE
  };

static int VORBIS_ERRNO = -1;

typedef SLCONST struct
{
   SLFUTURE_CONST char *msg;
   int sys_errno;
}
Errno_Map_Type;

static Errno_Map_Type Errno_Map [] =
{
# define NOTANOGGBTSTR 0
  {"Input does not appear to be an Ogg bitstream", NOTANOGGBTSTR},
# define EREADBTSTR 1
  {"Error reading Ogg bitstream data", EREADBTSTR},
# define EREADHEADPACK 2
  {"Error reading initial header packet, not an Ogg bitstream", EREADHEADPACK},
# define NOTVORBISAUDIO 3
 {"This Ogg bitstream does not contain Vorbis audio data", NOTVORBISAUDIO},
# define CORRUPTEDHEADER 4
  {"Corrupted secondary header", CORRUPTEDHEADER},
# define NOTALLVORBISHEADERS 5
  {"End of file before finding all Vorbis headers", NOTALLVORBISHEADERS},
# define NOTAFILEPTR 6
  {"Stack item is not a file type pointer", NOTAFILEPTR},
# define NOTASTRUCT 7
  {"Stack item is not a required struct", NOTASTRUCT},
  {NULL, 0},
};

static SLCONST char *vorbis_errno_string ()
{
  int err;

  if (SLang_Num_Function_Args == 0)
    err = VORBIS_ERRNO;
  else
    if (-1 == SLang_pop_int (&err))
      err = -1;

  Errno_Map_Type *e;

  e = Errno_Map;
  while (e->msg != NULL)
    {
    if (e->sys_errno == err)
      return e->msg;

    e++;
    }

  return "Unknown error";
}

ogg_int16_t convbuffer[4096]; /* take 8k out of the data segment, not the stack */

int convsize = 4096;

/* extern void _VDBG_dump (void); */

static void vorbis_decoder_intrin (void)
{
  SLang_MMT_Type *mmt = NULL;
  FILE *fp;
  FILE *outfp;
  int state_is_initialized = 0;
  int stkdepth;
  Vorbis_Type vt;

  ogg_sync_state   oy; /* sync and verify incoming physical bitstream */
  ogg_stream_state os; /* take physical pages, weld into a logical stream of packets */
  ogg_page         og; /* one Ogg bitstream page. Vorbis packets are inside */
  ogg_packet       op; /* one raw packet of data for decode */
  vorbis_info      vi; /* struct that stores all the static vorbis bitstream settings */
  vorbis_comment   vc; /* struct that stores all the bitstream user comments */
  vorbis_dsp_state vd; /* central working state for the packet->PCM decoder */
  vorbis_block     vb; /* local working space for packet->PCM decode */

  VORBIS_ERRNO = -1;

  if (-1 == SLang_pop_fileptr (&mmt, &fp))
    {
    VORBIS_ERRNO = NOTAFILEPTR;
    goto return_err_a;
    }

  if (-1 == SLang_pop_fileptr (&mmt, &outfp))
    {
    VORBIS_ERRNO = NOTAFILEPTR;
    goto return_err_a;
    }

  if (-1 == SLang_pop_cstruct ((VOID_STAR) &vt, Vorbis_Type_Layout))
    {
    VORBIS_ERRNO = NOTASTRUCT;
    goto return_err_a;
    }

  ogg_int64_t lgp = 0;
  ogg_int64_t gp; /* granular position */
  ogg_int64_t bt = 0;

  char *buffer;
  int  bytes;
  char buf[4096];
  int bts = 0;
  char msg[4096];

  long total_bytes;
  long bytes_proc = 0;

  if (vt.verbose)
    {
    fseek (fp, 0, SEEK_END);
    total_bytes = ftell (fp);
    }

  fseek (fp, 0, SEEK_SET);
  fseek (outfp, 0, SEEK_SET);

  /********** Decode setup ************/
  ogg_sync_init (&oy); /* Now we can read pages */

  while (1)
    { /* we repeat if the bitstream is chained */
    int eos = 0;
    int i;

    /* grab some data at the head of the stream. We want the first page
       (which is guaranteed to be small and only contain the Vorbis
       stream initial header) We need the first page to get the stream
       serialno. */

    /* submit a 4k block to libvorbis' Ogg layer */
    buffer = ogg_sync_buffer (&oy, 4096);

    bytes = fread (buffer, 1, 4096, fp);
    bytes_proc += bytes;

    ogg_sync_wrote (&oy, bytes);

    /* Get the first page. */
    if (ogg_sync_pageout (&oy, &og) != 1)
      {
      /* have we simply run out of data?  If so, we're done. */
      if (bytes < 4096)
        break;
      /* error case.  Must not be Vorbis data */
      VORBIS_ERRNO = NOTANOGGBTSTR;
      goto return_err_c;
      }

    /* Get the serial number and set up the rest of decode. */
    /* serialno first; use it to set up a logical stream */
    ogg_stream_init (&os, ogg_page_serialno (&og));

    /* extract the initial header from the first page and verify that the
       Ogg bitstream is in fact Vorbis data */

    /* handle the initial header first instead of just having the code
       read all three Vorbis headers at once because reading the initial
       header is an easy way to identify a Vorbis bitstream and it's
       useful to see that functionality seperated out. */

    vorbis_info_init (&vi);
    vorbis_comment_init (&vc);

    if (ogg_stream_pagein (&os, &og) < 0)
      {
      VORBIS_ERRNO = EREADBTSTR;
      goto return_err_d;
      }

    if (ogg_stream_packetout (&os, &op) != 1)
      {
      /* no page? must not be vorbis */
      VORBIS_ERRNO = EREADHEADPACK;
      goto return_err_d;
      }

    if (vorbis_synthesis_headerin (&vi, &vc, &op) < 0)
      {
      /* error case; not a vorbis header */
      VORBIS_ERRNO = NOTVORBISAUDIO;
      goto return_err_d;
      }

    gp = ogg_page_granulepos (&og);

    if (gp > lgp)
      lgp = gp;

    bt += (og.header_len + og.body_len);

    /* At this point, we're sure we're Vorbis. We've set up the logical
       (Ogg) bitstream decoder. Get the comment and codebook headers and
       set up the Vorbis decoder */

    /* The next two packets in order are the comment and codebook headers.
       They're likely large and may span multiple pages. Thus we read
       and submit data until we get our two packets, watching that no
       pages are missing. If a page is missing, error out; losing a
       header page is the only place where missing data is fatal. */

    i = 0;
    while (i < 2)
      {
      while (i < 2)
        {
        int result = ogg_sync_pageout (&oy, &og);

        if (result == 0)
          break; /* Need more data */

        gp = ogg_page_granulepos (&og);

        if (gp > lgp)
          lgp = gp;

        bt += (og.header_len + og.body_len);

        /* Don't complain about missing or corrupt data yet. We'll
           catch it at the packet output phase */
        if (result == 1)
          {
          ogg_stream_pagein (&os, &og); /* we can ignore any errors here
                                           as they'll also become apparent
                                           at packetout */
          while (i < 2)
            {
            result = ogg_stream_packetout (&os, &op);
            if (result == 0)
              break;

            if (result < 0)
              {
              /* Uh oh; data at some point was corrupted or missing!
                 We can't tolerate that in a header.  Die. */
              VORBIS_ERRNO = CORRUPTEDHEADER;
              goto return_err_d;
              }

            result = vorbis_synthesis_headerin (&vi, &vc, &op);
            if (result < 0)
              {
              VORBIS_ERRNO = CORRUPTEDHEADER;
              goto return_err_d;
              }

            i++;
            }
          }
        }

      /* no harm in not checking before adding more */
      buffer = ogg_sync_buffer (&oy, 4096);
      bytes = fread (buffer, 1, 4096, fp);
      bytes_proc += bytes;

      if (bytes == 0 && i < 2)
        {
        VORBIS_ERRNO = NOTALLVORBISHEADERS;
        goto return_err_d;
        }

      ogg_sync_wrote (&oy, bytes);
      }

    /* Throw the comments plus a few lines about the bitstream we're
       decoding */
    {
    char **ptr = vc.user_comments;
    while (*ptr)
      {
      bts += sprintf (buf+bts, "%s\n", *ptr);
      ++ptr;
      }

    bts += sprintf (buf+bts, "\nBitstream is %d channel, %ldHz\n", vi.channels, vi.rate);
    bts += sprintf (buf+bts, "Encoded by: %s\n\n", vc.vendor);
    }

    convsize = 4096 / vi.channels;

    /* OK, got and parsed all three headers. Initialize the Vorbis
       packet->PCM decoder. */
    if (vorbis_synthesis_init (&vd, &vi) == 0)
      { /* central decode state */
      vorbis_block_init (&vd, &vb); /* local state for most of the decode
                                       so multiple block decodes can
                                       proceed in parallel. We could init
                                       multiple vorbis_block structures
                                       for vd here */

      state_is_initialized = 1;

      /* The rest is just a straight decode loop until end of stream */
      while (!eos)
        {
        while (!eos)
          {
          int result = ogg_sync_pageout (&oy, &og);
          if (result == 0)
            break; /* need more data */

          gp = ogg_page_granulepos (&og);

          if (gp > lgp)
            lgp = gp;

          bt += (og.header_len + og.body_len);

          if (result < 0)
            /* missing or corrupt data at this page position */
            strcpy (msg + strlen (msg), "Corrupt or missing data in bitstream; "
               "continuing...\n");
          else
            {
            ogg_stream_pagein (&os, &og); /* can safely ignore errors at
                                           this point */
            while (1)
              {
              result = ogg_stream_packetout (&os, &op);

              if (result == 0)
                break; /* need more data */

              if (result < 0)
                { /* missing or corrupt data at this page position */
                /* no reason to complain; already complained above */
                }
              else
                {
                /* we have a packet.  Decode it */
                float **pcm;
                int samples;

                if (vorbis_synthesis (&vb, &op) == 0) /* test for success! */
                  vorbis_synthesis_blockin (&vd, &vb);
                /* 

                **pcm is a multichannel float vector.  In stereo, for
                example, pcm[0] is left, and pcm[1] is right.  samples is
                the size of each channel.  Convert the float values
                (-1.<=range<=1.) to whatever PCM format and write it out */

                while ((samples = vorbis_synthesis_pcmout (&vd, &pcm))> 0)
                  {
                  int j;
                  int bout = (samples < convsize ? samples : convsize);

                  /* convert floats to 16 bit signed ints (host order) and
                     interleave */
                  for (i = 0; i < vi.channels; i++)
                    {
                    ogg_int16_t *ptr = convbuffer+i;
                    float  *mono = pcm[i];
                    for (j = 0; j < bout; j++)
                      {
#if 1
                      int val = floor (mono[j] * 32767.f + .5f);
#else /* optional dither */
                      int val = mono[j] * 32767.f + drand48 () - 0.5f;
#endif
                      /* might as well guard against clipping */
                      if (val > 32767)
                        val = 32767;

                      if (val < -32768)
                        val = -32768;

                      *ptr=val;
                      ptr += vi.channels;
                    }
                  }

                  fwrite (convbuffer, 2 * vi.channels, bout, outfp);
                  vorbis_synthesis_read (&vd, bout); /* tell libvorbis how
                                                      many samples we
                                                      actually consumed */
                }
              }
            }

          if (ogg_page_eos (&og))
            eos = 1;

          if (vt.verbose)
            fprintf (stdout, "%.f%%\n", ((double) bytes_proc / total_bytes) * 100.0);
          }
        }

        if (!eos)
          {
          buffer = ogg_sync_buffer (&oy, 4096);
          bytes = fread (buffer, 1, 4096, fp);
          bytes_proc += bytes;

          ogg_sync_wrote (&oy, bytes);
          if (bytes == 0)
            eos = 1;
        }
      }

    /* ogg_page and ogg_packet structs always point to storage in
       libvorbis.  They're never freed or manipulated directly */

    vorbis_block_clear (&vb);
    vorbis_dsp_clear (&vd);
    }
  else
    strcpy (msg + strlen (msg), "Error: Corrupt header during playback initialization.\n");

  /* clean up this logical bitstream; before exit we see if we're
     followed by another [chained] */

  long minutes, seconds, milliseconds;
  double bitrate, time;

  /* This should be lastgranulepos - startgranulepos, or something like that*/
  time = (double) lgp / vi.rate;
  minutes = (long) time / 60;
  seconds = (long) time - minutes * 60;
  milliseconds = (long) ((time - minutes * 60 - seconds) * 1000);
  bitrate = bt * 8 / time / 1000.0;

  bts += sprintf (buf+bts, "Total data length: %d\n", (int) bt);
  bts += sprintf (buf+bts, "Playback length: %ldm:%02ld.%03lds\n",
    minutes, seconds, milliseconds);
  bts += sprintf (buf+bts, "Average bitrate: %f kb/s\n", bitrate);

  char *c = buf;
  vt.comments = c;

  c = msg;
  vt.msg = c;

  ogg_stream_clear (&os);
  vorbis_comment_clear (&vc);
  vorbis_info_clear (&vi);  /* must be called last */
  }

  /* OK, clean up the framer */
  ogg_sync_clear (&oy);

  SLang_free_mmt (mmt);

  SLang_push_cstruct ((VOID_STAR) &vt, Vorbis_Type_Layout);

  return;

return_err_d:
  if (state_is_initialized)
    {
    vorbis_block_clear (&vb);
    vorbis_dsp_clear (&vd);
    }

  ogg_stream_clear (&os);
  vorbis_comment_clear (&vc);
  vorbis_info_clear (&vi);

return_err_c:
  ogg_sync_clear (&oy);

  SLang_free_cstruct ((VOID_STAR) &vt, Vorbis_Type_Layout);

  stkdepth = SLstack_depth ();

return_err_a:
  if (mmt)
    SLang_free_mmt (mmt);

  if (stkdepth)
    SLdo_pop_n (stkdepth);

  SLang_push_null ();
}

static SLang_Intrin_Var_Type vorbis_Variables [] =
{
  MAKE_VARIABLE("vorbis_errno", &VORBIS_ERRNO, SLANG_INT_TYPE, 1),
  SLANG_END_TABLE
};

static SLang_Intrin_Fun_Type vorbis_Intrinsics [] =
{
  MAKE_INTRINSIC_0("__vorbis_decode", vorbis_decoder_intrin, VOID_TYPE),
  MAKE_INTRINSIC_0("__vorbis_errno_string", (FVOID_STAR) vorbis_errno_string, SLANG_STRING_TYPE),

  SLANG_END_INTRIN_FUN_TABLE
};

int init_vorbis_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, vorbis_Intrinsics, NULL)
    ||-1 == SLadd_intrin_var_table (vorbis_Variables, NULL))
    return -1;

  return 0;
}
