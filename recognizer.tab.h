/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_RECOGNIZER_TAB_H_INCLUDED
# define YY_YY_RECOGNIZER_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    END = 258,
    PROGRAM = 259,
    BGIN = 260,
    DO_IF = 261,
    DO_IF_ELSE = 262,
    DO_UNTIL = 263,
    DO_WHILE = 264,
    PRINT = 265,
    READ = 266,
    EQUIVAL = 267,
    EQUAL = 268,
    LESS = 269,
    GREATER = 270,
    SUM = 271,
    SUBSTRACT = 272,
    MULTI = 273,
    DIVIDE = 274,
    PAREN_I = 275,
    PAREN_D = 276,
    S_BRACKET_I = 277,
    S_BRACKET_D = 278,
    SEMICOLON = 279,
    COLON = 280,
    COMMA = 281,
    OTHER = 282,
    INTEGER = 283,
    FLOATING = 284,
    CONS = 285,
    VAR = 286,
    BLOCK = 287,
    NUM_I = 288,
    NUM_F = 289,
    IDENTIF = 290
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 93 "recognizer.y"

   unsigned char this_id[45 + 1];
   char this_type;
   int this_int;
   float this_float;
   struct asr * this_tree;
   struct lst * this_list;

#line 102 "recognizer.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_RECOGNIZER_TAB_H_INCLUDED  */
