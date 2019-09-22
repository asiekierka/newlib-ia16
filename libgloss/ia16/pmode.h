/*
 * Macros for protected mode operation.
 *
 * Copyright (c) 2019 TK Chia
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#ifdef __ASSEMBLER__
/*
 * DPMI mode is not really supported for the medium model yet.  For now, just
 * do plain old `int $0x21' calls when using the medium model, even if
 * -mprotected-mode is specified.
 */
# if defined __IA16_FEATURE_PROTECTED_MODE && ! defined __IA16_CMODEL_MEDIUM__
#   define RMODE_DOS_CALL_ call __ia16_rmode_dos_call
#   define RMODE_FUNC_CALL_BX_ call __ia16_rmode_func_call_bx
# else
#   define RMODE_DOS_CALL_ int $0x21
#   define RMODE_FUNC_CALL_BX_ callw *%bx
# endif
#else
# if defined __IA16_FEATURE_PROTECTED_MODE && ! defined __IA16_CMODEL_MEDIUM__
#   define RMODE_DOS_CALL_ "call __ia16_rmode_dos_call"
#   define RMODE_FUNC_CALL_BX_ "call __ia16_rmode_func_call_bx"
# else
#   define RMODE_DOS_CALL_ "int $0x21"
#   define RMODE_FUNC_CALL_BX_ "callw *%bx"
# endif
#endif
