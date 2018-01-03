/*
 * original code by http://web.science.mq.edu.au/~arikm/code/
 * some code changes by Agathoklis Chatzimanikas
 */
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>
#include <slang.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>
#include <openssl/evp.h>
#include <openssl/ssl.h>

static void sl_encrypt (void){
  /* input types */
  char *ctype;
  unsigned char *outbuf, *iiv, *ikey, *idata;
  SLang_BString_Type *iv, *key, *data;
  /* internal types */
  EVP_CIPHER_CTX ctx;
  const EVP_CIPHER *cipher;
  int outlen, tmplen, dlen, i;
  /* output types */
  SLang_BString_Type *output;

  if (SLang_Num_Function_Args != 4 ||
      SLang_pop_slstring(&ctype) == -1 ){
    return; }

  cipher = EVP_get_cipherbyname(ctype);
  if (!cipher){
    SLang_verror(SL_UNDEFINED_NAME,"could not find cipher %s",ctype);
    return;
  }

  if (SLang_pop_bstring(&iv) == -1 ||
      SLang_pop_bstring(&key) == -1 ||
      SLang_pop_bstring(&data) == -1 ){
    return; }

  iiv = SLbstring_get_pointer (iv,&i);
  ikey = SLbstring_get_pointer (key,&i);
  idata = SLbstring_get_pointer (data,&dlen);

  outbuf = (char*)malloc(dlen+EVP_CIPHER_block_size(cipher));

  EVP_CIPHER_CTX_init(&ctx);
  EVP_EncryptInit_ex(&ctx, cipher, NULL, ikey, iiv);

  if (!EVP_EncryptUpdate(&ctx, outbuf, &outlen, idata, dlen)){
    return; /*emit an error here*/
  }
  if (!EVP_EncryptFinal(&ctx, outbuf + outlen, &tmplen)){
    return; /*emit an error here*/
  }
  outlen+=tmplen;

  output = SLbstring_create (outbuf, outlen);

  SLang_push_bstring(output);
  SLbstring_free(output);
  SLbstring_free(data);
  SLbstring_free(key);
  SLbstring_free(iv);
  free(outbuf);
}

static void sl_decrypt (void){
  /* input types */
  char *ctype;
  unsigned char *outbuf, *iiv, *ikey, *idata;
  SLang_BString_Type *iv, *key, *data;
  /* internal types */
  EVP_CIPHER_CTX ctx;
  const EVP_CIPHER *cipher;
  int outlen, tmplen, dlen, i;
  /* output types */
  SLang_BString_Type *output;

  if (SLang_Num_Function_Args != 4 ||
      SLang_pop_slstring(&ctype) == -1 ){
    return; }

  cipher = EVP_get_cipherbyname(ctype);
  if (!cipher){
    (void) SLang_push_null ();
    return;
  }

  if (SLang_pop_bstring(&iv) == -1 ||
      SLang_pop_bstring(&key) == -1 ||
      SLang_pop_bstring(&data) == -1 ){
    return; }

  iiv = SLbstring_get_pointer (iv,&i);
  ikey = SLbstring_get_pointer (key,&i);
  idata = SLbstring_get_pointer (data,&dlen);

  outbuf = (char*)malloc(dlen+EVP_CIPHER_block_size(cipher));

  EVP_CIPHER_CTX_init(&ctx);
  EVP_DecryptInit_ex(&ctx, cipher, NULL, ikey, iiv);

  if (!EVP_DecryptUpdate(&ctx, outbuf, &outlen, idata, dlen)){
    (void) SLang_push_null ();
    SLbstring_free(data);
    SLbstring_free(key);
    SLbstring_free(iv);
    free(outbuf);
    return;
  }

  if (!EVP_DecryptFinal(&ctx, outbuf + outlen, &tmplen)){
    (void) SLang_push_null ();
    SLbstring_free(data);
    SLbstring_free(key);
    SLbstring_free(iv);
    free(outbuf);
    return;
  }

  outlen+=tmplen;

  output = SLbstring_create (outbuf, outlen);

  SLang_push_bstring(output);
  SLbstring_free(output);
  SLbstring_free(data);
  SLbstring_free(key);
  SLbstring_free(iv);
  free(outbuf);
}

static void sl_generate_key (void){
  char* pass, *ctype, *dtype;
  SLang_BString_Type* salta;
  const EVP_CIPHER *cipher;
  const EVP_MD *md;
  unsigned char *salt;
  unsigned char *key;
  unsigned char *iv;
  SLang_BString_Type* outkey, *outiv;
  int count,i,keylen,ivlen,saltlen;

  if (SLang_Num_Function_Args != 5 ||
      SLang_pop_slstring(&dtype) == -1 ||
      SLang_pop_slstring(&ctype) == -1 ){
    return; }

  cipher = EVP_get_cipherbyname(ctype);
  if (!cipher){
    SLang_verror(SL_UNDEFINED_NAME,"could not find cipher %s",ctype);
    SLang_free_slstring(ctype);
    return;
  }
  md = EVP_get_digestbyname(dtype);
  if (!md){
    SLang_verror(SL_UNDEFINED_NAME,"could not find digest %s",dtype);
    SLang_free_slstring(ctype);
    SLang_free_slstring(dtype);
    return;
  }

  if (SLang_pop_integer(&count) == -1 ||
      SLang_pop_bstring(&salta) == -1 ||
      SLang_pop_slstring(&pass) == -1 ){
    return; }

  keylen = EVP_CIPHER_key_length(cipher);
  ivlen  = EVP_CIPHER_iv_length(cipher);
  key = (char*)malloc(keylen);
  iv  = (char*)malloc(ivlen);

  salt = SLbstring_get_pointer(salta,&saltlen);

  if (saltlen==0){
    salt=NULL;
  }
  else if (saltlen!=8){
    SLang_verror(SL_USAGE_ERROR,"Salt must not exceed 8 bytes");
    SLbstring_free(salta);
    SLang_free_slstring(pass);
    SLang_free_slstring(ctype);
    SLang_free_slstring(dtype);
    return;
  }


  EVP_BytesToKey(cipher,md,salt,pass,(int)strlen(pass),count,key,iv);

  outkey = SLbstring_create(key, keylen);
  outiv  = SLbstring_create(iv, ivlen);

  SLang_push_bstring(outkey);
  SLang_push_bstring(outiv);
  SLbstring_free(salta);
  SLbstring_free(outkey);
  SLbstring_free(outiv);
  SLang_free_slstring(pass);
  SLang_free_slstring(ctype);
  SLang_free_slstring(dtype);
  free(key);free(iv);
}

#define SSL_PROTO_SSL2 0
#define SSL_PROTO_SSL3 1
#define SSL_PROTO_TLS1 2
#define SSL_PROTO_SSL23 3
#define SSL_PROTO_ANY 4

static int SLsslctx_Type_Id = -1;
typedef struct
{
  void *ctx;
  int is_server;
}
SLsslctx_Type;

static int SLssl_Type_Id = -1;
typedef struct
{
  void *ssl;
  int is_server;
}
SLssl_Type;


static void sl_destroy_ssl (SLtype type, VOID_STAR f){
  SLssl_Type *ssl;
  ssl=(SLssl_Type *)f;
  SSL_free((SSL *)(ssl->ssl));
}
static void sl_destroy_sslctx (SLtype type, VOID_STAR f){
  SLsslctx_Type *ctx;
  ctx=(SLsslctx_Type *)f;
  SSL_CTX_free((SSL_CTX *)(ctx->ctx));
}

static int register_classes (void)
{
  SLang_Class_Type *cl,*cl2;

  if (SLssl_Type_Id != -1)
    return 0;

  if (NULL == (cl = SLclass_allocate_class ("SLssl_Type")))
    return -1;

  (void) SLclass_set_destroy_function (cl, sl_destroy_ssl);

  if (-1 == SLclass_register_class (cl, SLANG_VOID_TYPE,
                                    sizeof (SLssl_Type),
                                    SLANG_CLASS_TYPE_MMT))
    return -1;

  SLssl_Type_Id = SLclass_get_class_id (cl);

  if (NULL == (cl2 = SLclass_allocate_class ("SLsslctx_Type")))
    return -1;

  (void) SLclass_set_destroy_function (cl2, sl_destroy_sslctx);

  if (-1 == SLclass_register_class (cl2, SLANG_VOID_TYPE,
                                    sizeof (SLsslctx_Type),
                                    SLANG_CLASS_TYPE_MMT))
    return -1;

  SLsslctx_Type_Id = SLclass_get_class_id (cl2);

  return 0;
}

static SLang_Intrin_Fun_Type Module_Intrinsics [] = {
  MAKE_INTRINSIC_0("_encrypt",sl_encrypt,SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("_decrypt",sl_decrypt,SLANG_VOID_TYPE),
  MAKE_INTRINSIC_0("_genkeyiv",sl_generate_key,SLANG_VOID_TYPE),
  SLANG_END_INTRIN_FUN_TABLE
};

static SLang_IConstant_Type Module_IConstants [] =
  {
    MAKE_ICONSTANT("SSL_FILETYPE_ASN1",SSL_FILETYPE_ASN1),
    MAKE_ICONSTANT("SSL_FILETYPE_PEM",SSL_FILETYPE_PEM),
    MAKE_ICONSTANT("SSL_PROTO_SSL2",SSL_PROTO_SSL2),
    MAKE_ICONSTANT("SSL_PROTO_SSL3",SSL_PROTO_SSL3),
    MAKE_ICONSTANT("SSL_PROTO_TLS1",SSL_PROTO_TLS1),
    MAKE_ICONSTANT("SSL_PROTO_SSL23",SSL_PROTO_SSL23),
    MAKE_ICONSTANT("SSL_PROTO_ANY",SSL_PROTO_ANY),
    SLANG_END_ICONST_TABLE
  };

SLANG_MODULE(crypto);

int init_crypto_module_ns (char *ns_name){
  SLang_NameSpace_Type *ns = SLns_create_namespace(ns_name);
  if (ns == NULL)
    return -1;

  if (-1 == register_classes ())
    return -1;

  if (
      (-1 == SLns_add_intrin_fun_table (ns, Module_Intrinsics, NULL)) ||
      (-1 == SLns_add_iconstant_table (ns, Module_IConstants, NULL))
      )
    return -1;

  SSL_library_init();
  OpenSSL_add_all_algorithms();

  return 0;
}
