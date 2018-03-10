#include <stdio.h>
#include <unistd.h>
#include <mpg123.h>
#include <slang.h>

SLANG_MODULE(mpg);

#define INBUFF  16384
#define OUTBUFF 32768

#define ifnot(x) if (x == 0)
#define forever while (1)

int MPG_IS_INITIALIZED = 0;

static int __ERRNO__ = -13;

typedef SLCONST struct
  {
  SLFUTURE_CONST char *msg;
  int __errno;
  } Errno_Map_Type;

static Errno_Map_Type Errno_Map [] =
  {
#ifndef NOTAFD
#define NOTAFD 257
#endif
  {"Stack item is not a file descriptor", NOTAFD},
  {"Message: Track ended. Stop decoding", MPG123_DONE},
  {"Message: Output format will be different on next call. Note that some libmpg123 versions between 1.4.3 and 1.8.0 insist on you calling mpg123_getformat() after getting this message code. Newer verisons behave like advertised: You have the chance to call mpg123_getformat(), but you can also just continue decoding and get your data", MPG123_NEW_FORMAT},
  {"Message: For feed reader: (call mpg123_feed() or mpg123_decode() with some new input data)", MPG123_NEED_MORE},
  {"Generic Error", MPG123_ERR},
  {"Unable to set up output format", MPG123_BAD_OUTFORMAT},
  {"Invalid channel number specified",	MPG123_BAD_CHANNEL},
	 {"Invalid sample rate specified", 	MPG123_BAD_RATE},
	 {"Unable to allocate memory for 16 to 8 converter table", MPG123_ERR_16TO8TABLE},
  {"Bad parameter id", MPG123_BAD_PARAM},
  {"Bad buffer given -- invalid pointer or too small size", MPG123_BAD_BUFFER},
  {"Out of memory -- some malloc() failed", MPG123_OUT_OF_MEM},
  {"You didn't initialize the library", MPG123_NOT_INITIALIZED},
  {"Invalid decoder choice", MPG123_BAD_DECODER},
  {"Invalid mpg123 handle", MPG123_BAD_HANDLE},
  {"Unable to initialize frame buffers", MPG123_NO_BUFFERS},
  {"Invalid RVA mode", MPG123_BAD_RVA},
  {"This build doesn't support gapless decoding", MPG123_NO_GAPLESS},
  {"Not enough buffer space", MPG123_NO_SPACE},
  {"Incompatible numeric data types", MPG123_BAD_TYPES},
  {"Bad equalizer band", MPG123_BAD_BAND},
  {"Null pointer given where valid storage address needed", MPG123_ERR_NULL},
  {"Error reading the stream", MPG123_ERR_READER},
  {"Cannot seek from end", MPG123_NO_SEEK_FROM_END},
  {"Invalid 'whence' for seek function", MPG123_BAD_WHENCE},
  {"Build does not support stream timeouts", MPG123_NO_TIMEOUT},
  {"File access error", MPG123_BAD_FILE},
  {"Seek not supported by stream", MPG123_NO_SEEK},
  {"No stream opened", MPG123_NO_READER},
  {"Bad parameter handle", MPG123_BAD_PARS},
  {"Bad parameters to mpg123_index() and mpg123_set_index()", MPG123_BAD_INDEX_PAR},
  {"Lost track in bytestream and did not try to resync", MPG123_OUT_OF_SYNC},
  {"Resync failed to find valid MPEG data", MPG123_RESYNC_FAIL},
  {"No 8bit encoding possible", MPG123_NO_8BIT},
  {"Stack aligmnent error", MPG123_BAD_ALIGN},
  {"NULL input buffer with non-zero size..", MPG123_NULL_BUFFER},
  {"Relative seek not possible (screwed up file offset)", MPG123_NO_RELSEEK},
  {"You gave a null pointer somewhere where you shouldn't have", MPG123_NULL_POINTER},
  {"Bad key value given", MPG123_BAD_KEY},
  {"No frame index in this build", MPG123_NO_INDEX},
  {"Something with frame index went wrong", MPG123_INDEX_FAIL},
  {"Something prevents a proper decoder setup", MPG123_BAD_DECODER_SETUP},
  {"This feature has not been built into libmpg123", MPG123_MISSING_FEATURE},
  {"A bad value has been given, somewhere", MPG123_BAD_VALUE},
  {"Low-level seek failed", MPG123_LSEEK_FAILED},
  {"Custom I/O not prepared", MPG123_BAD_CUSTOM_IO},
  {"Offset value overflow during translation of large file API calls -- your client program cannot handle that large file", MPG123_LFS_OVERFLOW},
  {"Some integer overflow", MPG123_INT_OVERFLOW},
  {NULL, 0},
  };

static char *__errno_string__ (void)
{
  Errno_Map_Type *e;
  int err;

  if (SLang_Num_Function_Args == 0)
    err = __ERRNO__;
  else
    if (-1 == SLang_pop_int (&err))
      err = -1;

  __ERRNO__ = -1;

  e = Errno_Map;

  while (e->msg != NULL)
    {
    if (e->__errno == err)
      return e->msg;

    e++;
    }

  return "Unknown error";
}

static void clear_stack (void)
{
  if (SLstack_depth ())
    SLdo_pop_n (SLstack_depth ());
}

static void __mpg_init (void)
{
  if (MPG_IS_INITIALIZED)
    return;

  mpg123_init ();
  MPG_IS_INITIALIZED = 1;
}

static void __mpg_deinit (void)
{
  ifnot (MPG_IS_INITIALIZED)
    return;

  mpg123_exit ();
  MPG_IS_INITIALIZED = 0;
}

static void __mpg_decode (void)
{
  int retval = 0, ret;
  unsigned char buf[INBUFF];
  unsigned char out[OUTBUFF];
  int infd, outfd;
  SLFile_FD_Type *fin = NULL, *fout = NULL;

  size_t size;
  ssize_t len;

	 mpg123_handle *mh = NULL;

  ifnot (MPG_IS_INITIALIZED)
    __mpg_init ();

  if (-1 == SLfile_pop_fd (&fout))
    {
    __ERRNO__ = NOTAFD;
    goto __error;
    }

  if (-1 == SLfile_get_fd (fout, &outfd))
    goto __error;

  if (-1 == SLfile_pop_fd (&fin))
    {
    __ERRNO__ = NOTAFD;
    goto __error;
    }

  if (-1 == SLfile_get_fd (fin, &infd))
    goto __error;

  mh = mpg123_new (NULL, &ret);

	 if (mh == NULL)
   	{
    __ERRNO__ = ret;
    goto __error;
    }

  mpg123_param (mh, MPG123_VERBOSE, 2, 0);
  mpg123_open_feed (mh);

	 forever
	   {
		  len = read (infd, buf, INBUFF);

		  if (len <= 0)
  			 goto __return;

		  ret = mpg123_decode (mh, buf, len, out, OUTBUFF, &size);

		  if (ret == MPG123_NEW_FORMAT)
		    {
			   long rate;
			   int channels, enc;
			   mpg123_getformat (mh, &rate, &channels, &enc);
			   fprintf(stderr, "New format: %li Hz, %i channels, encoding value %i\n", rate, channels, enc);
		    }
    else
      ifnot ((ret == MPG123_OK))
        {
        retval = -1;
        __ERRNO__ = ret;
        goto __return;
        }

		  write (outfd, out, size);

		  while (ret != MPG123_ERR && ret != MPG123_NEED_MORE)
		    {
			   ret = mpg123_decode (mh, NULL, 0, out, OUTBUFF, &size);
			   write (outfd, out, size);
		    }

		  if (ret == MPG123_ERR)
      {
      __ERRNO__ = ret;
      retval = -1;
      goto __return;
      }
	  }

__error:
  retval = -1;
  clear_stack ();

__return:
  ifnot ((NULL == fout))
    SLfile_free_fd (fout);

  ifnot ((NULL == fin))
    SLfile_free_fd (fin);

  ifnot ((NULL == mh))
   	{
    mpg123_close (mh);
	   mpg123_delete (mh);
    }

  SLang_push_int (retval);
}

static SLang_Intrin_Fun_Type Intrinsics [] =
{
  MAKE_INTRINSIC_0("__mpg_errno_string", __errno_string__, SLANG_STRING_TYPE),
  MAKE_INTRINSIC_0("__mpg_decode",  __mpg_decode, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("__mpg_deinit", __mpg_deinit, SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("__mpg_init", __mpg_init, SLANG_VOID_TYPE),
  SLANG_END_INTRIN_FUN_TABLE
};

int init_mpg_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, Intrinsics, NULL))
    return -1;

  return 0;
}
