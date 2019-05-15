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
# ifdef __IA16_FEATURE_PROTECTED_MODE
#   define REAL_DOS_CALL_ call __ia16_real_dos_call
# else
#   define REAL_DOS_CALL_ int $0x21
# endif
#else
# ifdef __IA16_FEATURE_PROTECTED_MODE
#   define REAL_DOS_CALL_ "call __ia16_real_dos_call"
# else
#   define REAL_DOS_CALL_ "int $0x21"
# endif
#endif
