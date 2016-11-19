 /*
  * This is a S-Lang binding to TagLib an Audio meta-data library
  * http://developer.kde.org/~wheeler/taglib.html
  *
  * Initial code written by Agathoklis D. Chatzimanikas
  * You may distribute this code under the terms of the
  * GNU General Public License.
  */

#include <taglib/tag_c.h>
#include <slang.h>

SLANG_MODULE(taglib);

typedef struct
  {
  char *title;
  char *artist;
  char *album;
  char *comment;
  char *genre;
  int track;
  int year;
  } TagLib;

static SLang_CStruct_Field_Type TagLib_Struct [] =
{
  MAKE_CSTRUCT_FIELD(TagLib, title, "title", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD(TagLib, artist, "artist", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD(TagLib, album, "album", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD(TagLib, comment, "comment", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_FIELD(TagLib, genre, "genre", SLANG_STRING_TYPE, 0),
  MAKE_CSTRUCT_INT_FIELD(TagLib, track, "track", 0),
  MAKE_CSTRUCT_INT_FIELD(TagLib, year, "year", 0),
  SLANG_END_CSTRUCT_TABLE
};

static int tagwrite_intrinsic (void)
{
  TagLib tags;
  TagLib_File *file;
  TagLib_Tag *tag;
  char *fname;
  
  if (-1 == SLang_pop_cstruct ((VOID_STAR)&tags, TagLib_Struct))
    return -1;

  if (-1 == SLpop_string (&fname))
    {
    SLang_free_cstruct ((VOID_STAR)&tags, TagLib_Struct);
    return -1;
    }

  file = taglib_file_new (fname);
  SLfree (fname);
  
  if (file == NULL)
    {
    SLang_free_cstruct ((VOID_STAR)&tags, TagLib_Struct);
    return -1;
    }

  taglib_set_strings_unicode (1);
  tag = taglib_file_tag (file);

  if (tag == NULL)
    {
    SLang_free_cstruct ((VOID_STAR)&tags, TagLib_Struct);
    taglib_file_free (file);
    return -1;
    }

  taglib_tag_set_title (tag, tags.title);
  taglib_tag_set_artist (tag, tags.artist);
  taglib_tag_set_album (tag, tags.album);
  taglib_tag_set_comment (tag, tags.comment);
  taglib_tag_set_genre (tag, tags.genre);
  taglib_tag_set_year (tag, tags.year);
  taglib_tag_set_track (tag, tags.track);

  taglib_file_save (file);
  taglib_tag_free_strings ();
  taglib_file_free (file);
  
  SLang_free_cstruct ((VOID_STAR)&tags, TagLib_Struct);
  return 0;
}

static void tagread_intrinsic (char *fname)
{
  TagLib tags;
  TagLib_File *file;
  TagLib_Tag *tag;

  taglib_set_strings_unicode (1);

  file = taglib_file_new (fname);

  if (file == NULL)
    {
    (void) SLang_push_null ();
    return;
    }

  tag = taglib_file_tag (file);

  if (tag == NULL)
    {
    taglib_file_free (file);
    (void) SLang_push_null ();
    }

  tags.title = taglib_tag_title (tag);
  tags.artist = taglib_tag_artist (tag);
  tags.album = taglib_tag_album (tag);
  tags.comment = taglib_tag_comment (tag);
  tags.genre = taglib_tag_genre (tag);
  tags.year = taglib_tag_year (tag);
  tags.track = taglib_tag_track (tag);

  SLang_push_cstruct ((VOID_STAR) &tags, TagLib_Struct);

  taglib_tag_free_strings ();
  taglib_file_free (file);
}

static SLang_Intrin_Fun_Type taglib_Intrinsics [] =
{
  MAKE_INTRINSIC_S("tagread", tagread_intrinsic, VOID_TYPE),
  MAKE_INTRINSIC_0("tagwrite", tagwrite_intrinsic, SLANG_INT_TYPE),
  SLANG_END_INTRIN_FUN_TABLE
};

int init_taglib_module_ns (char *ns_name)
{
  SLang_NameSpace_Type *ns;

  if (NULL == (ns = SLns_create_namespace (ns_name)))
    return -1;

  if (-1 == SLns_add_intrin_fun_table (ns, taglib_Intrinsics, NULL))
    return -1;
  
  return 0;
}
