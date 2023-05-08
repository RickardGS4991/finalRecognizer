/* Luis Fernando Tuxpan Gutierrez - A01329747 */
/* Ricardo Garcia Sedano - A01329022 */
/* Ian Calhy Vázquez Domínguez - A01423732 */
/* Compiler design */
/* ITESM, campus Puebla */

/* Syntactic recognizer that checks the correctness of a file and then executes
   the instructions of the read file as a program.
*/

/* To compile and run the program, the following commands must be executed:
   (flex recognizer.lex) && (bison -d recognizer.y) && (gcc lex.yy.c recognizer.tab.c -lfl)
   ./a.out tests/filename.txt
*/


%{

// Libraries
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Constants
#define LENGTH 45 // Maximum name length for identifiers
#define N 5000 // Number of buckets in hash table

// Structure to make the reduced syntax tree
typedef struct asr ASR;
struct asr {
   int node_type;
   unsigned char name[LENGTH + 1];
   char value_type;
   int int_value;
   float float_value;
   ASR * left;
   ASR * right;
   ASR * next;
};

// Structure to make the symbols auxiliary list
typedef struct lst LST;
struct lst
{
   unsigned char name[LENGTH + 1];
   char value_type;
   LST * next;
};

// Structure to make the symbols table
typedef struct sym SYM;
struct sym
{
   unsigned char name[LENGTH + 1];
   char value_type;
   int int_value;
   float float_value;
   SYM * next;
};

// External variables of the lex file
extern int yylex();
extern FILE *yyin;
extern int line;

// Prototypes of functions
int yyerror(char const * s);
ASR * new_tree_node(int, unsigned char [], char, int, float, ASR *, ASR *, ASR *);
LST * new_list_node(unsigned char [], int, LST *);
LST * get_list_tail(LST *);
SYM * new_table_node(unsigned char [], int);
SYM * search_symbol(unsigned char []);
unsigned int hash(unsigned char []);
int expr_int_value(ASR * root);
float expr_float_value(ASR * root);
char expr_value_type(ASR * root);
char check_types(ASR *);
void assign_type(LST *, int);
void init_table();
void insert_table_node(SYM *);
void init_table();
void check_tree(ASR *);
void print_tree(ASR *, int);
void print_list(LST *);
void print_table();

// Data structures
ASR *tree = NULL; // Tree
LST *list = NULL; // List
SYM *table[N]; // Hash table

%}


%union{
   unsigned char this_id[45 + 1];
   char this_type;
   int this_int;
   float this_float;
   struct asr * this_tree;
   struct lst * this_list;
}

/* Terminal elements of grammar */
%token END PROGRAM BGIN DO_IF DO_IF_ELSE DO_UNTIL DO_WHILE PRINT READ EQUIVAL EQUAL LESS GREATER SUM SUBSTRACT MULTI DIVIDE PAREN_I PAREN_D S_BRACKET_I S_BRACKET_D SEMICOLON COLON COMMA OTHER INTEGER FLOATING CONS VAR BLOCK
%token<this_int> NUM_I
%token<this_float> NUM_F
%token<this_id> IDENTIF
%type <this_type> type
%type <this_tree> stmt stmt_lst expr term factor expresion opt_stmts
%type <this_list> opt_decls decl_lst decl id_list
%start prog


%%

// Start of grammar

// prog -> program id opt decls begin opt stmts end
prog: PROGRAM IDENTIF opt_decls BGIN opt_stmts END { list = $3; tree = $5; } // 'Compiled' code is executed after validating
;

// opt decls -> decl lst | ε
opt_decls: decl_lst                                                                                            { $$ = $1; }
         | /* empty*/                                                                                          { $$ = NULL; }
;

// decl lst -> decl; decl | decl
decl_lst: decl SEMICOLON decl_lst                                                                              { get_list_tail($1) -> next = $3; $$ = $1; }
        | decl                                                                                                 { $$ = $1; }
;

// decl -> type: id list
decl: type COLON id_list                                                                                       { assign_type($3, $1); $$ = $3; }
;

// id list -> id, id list | id
id_list: IDENTIF COMMA id_list                                                                                 { LST *n = new_list_node($1, 0, $3); SYM *n2 = new_table_node($1, 0); if (search_symbol($1) != NULL){ yyerror("Variable already declared."); } insert_table_node(n2); $$ = n; }
       | IDENTIF                                                                                               { LST *n = new_list_node($1, 0, NULL); SYM *n2 = new_table_node($1, 0); if (search_symbol($1) != NULL) { yyerror("Variable already declared."); } insert_table_node(n2); $$ = n; }
;

// type -> int | float
type: INTEGER                                                                                                  { $$ = 'i'; }
    | FLOATING                                                                                                 { $$ = 'f'; }
;

// stmt -> id := expr
//       | do-if (expresion) [opt stmts]
//       | do-ifelse (expresion) [opt stmts] [opt stmts]
//       | do-until (expresion) [opt stmts]
//       | do-while (expresion) [opt stmts]
//       | print expr
//       | read id
stmt: IDENTIF EQUIVAL expr                                                                                     { SYM *n = search_symbol($1); if (n == NULL) { yyerror("Variable not declared."); } if (n -> value_type != check_types($3)) { yyerror("Invalid types between operation."); } $$ = new_tree_node(BLOCK, ";", '0', 0, 0.0, new_tree_node(EQUIVAL, "equival", '0', 0, 0.0, new_tree_node(VAR, $1, '0', 0, 0.0, NULL, NULL, NULL), $3, NULL), NULL, NULL); }
    | DO_IF PAREN_I expresion PAREN_D S_BRACKET_I opt_stmts S_BRACKET_D                                        { $$ = new_tree_node(BLOCK, ";", '0', 0, 0.0, new_tree_node(DO_IF, "do_if", '0', 0, 0.0, $3, $6, NULL), NULL, NULL); }
    | DO_IF_ELSE PAREN_I expresion PAREN_D S_BRACKET_I opt_stmts S_BRACKET_D S_BRACKET_I opt_stmts S_BRACKET_D { $$ = new_tree_node(BLOCK, ";", '0', 0, 0.0, new_tree_node(DO_IF_ELSE, "do_if_else", '0', 0, 0.0, $3, $6, $9), NULL, NULL); }
    | DO_UNTIL PAREN_I expresion PAREN_D S_BRACKET_I opt_stmts S_BRACKET_D                                     { $$ = new_tree_node(BLOCK, ";", '0', 0, 0.0, new_tree_node(DO_UNTIL, "do_until", '0', 0, 0.0, $6, NULL, $3), NULL, NULL); }
    | DO_WHILE PAREN_I expresion PAREN_D S_BRACKET_I opt_stmts S_BRACKET_D                                     { $$ = new_tree_node(BLOCK, ";", '0', 0, 0.0, new_tree_node(DO_WHILE, "do_while", '0', 0, 0.0, $6, NULL, $3), NULL, NULL); }
    | PRINT expr                                                                                               { $$ = new_tree_node(BLOCK, ";", '0', 0, 0.0, new_tree_node(PRINT, "print", '0', 0, 0.0, $2, NULL, NULL), NULL, NULL); }
    | READ IDENTIF                                                                                             { SYM *n = search_symbol($2); if (n == NULL) { yyerror("Variable not declared."); } $$ = new_tree_node(BLOCK, ";", '0', 0, 0.0, new_tree_node(READ, "read", '0', 0, 0.0, new_tree_node(VAR, $2, '0', 0, 0.0, NULL, NULL, NULL), NULL, NULL), NULL, NULL); }
;

// opt stmts -> stmt lst | ε
opt_stmts: stmt_lst                                                                                            { $$ = $1; }
         | /* empty*/                                                                                          { $$ = NULL; }
;

// stmt lst -> stmt ; stmt lst | stmt
stmt_lst: stmt SEMICOLON stmt_lst                                                                              { $1 -> next = $3, $$ = $1; }
        | stmt                                                                                                 { $$ = $1; }
;

// expr -> expr + term
//       | expr - term
//       | term
expr : expr SUM term                                                                                           { char c1 = check_types($1); if (c1 != check_types($3)) { yyerror("Invalid types between operation."); } $$ = new_tree_node(SUM, "+", c1, 0, 0.0, $1, $3, NULL); }
     | expr SUBSTRACT term                                                                                     { char c1 = check_types($1); if (c1 != check_types($3)) { yyerror("Invalid types between operation."); } $$ = new_tree_node(SUBSTRACT, "-", c1, 0, 0.0, $1, $3, NULL); }
     | term
;

// term -> term * factor
//       | term / factor
//       | factor
term : term MULTI factor                                                                                       { char c1 = check_types($1); if (c1 != check_types($3)) { yyerror("Invalid types between operation."); } $$ = new_tree_node(MULTI, "*", c1, 0, 0.0, $1, $3, NULL); }
     | term DIVIDE factor                                                                                      { char c1 = check_types($1); if (c1 != check_types($3)) { yyerror("Invalid types between operation."); } $$ = new_tree_node(DIVIDE, "/", c1, 0, 0.0, $1, $3, NULL); }
     | factor
;

// factor -> ( expr )
//         | id
//         | numint
//         | numfloat
factor : PAREN_I expr PAREN_D                                                                                  { $$ = $2; }
       | IDENTIF                                                                                               { if (search_symbol($1) == NULL) { yyerror("Variable not declared."); } $$ = new_tree_node(VAR, $1, '0', 0, 0.0, NULL, NULL, NULL); }
       | NUM_I                                                                                                 { $$ = new_tree_node(CONS, "num", 'i', $1, $1, NULL, NULL, NULL); }
       | NUM_F                                                                                                 { $$ = new_tree_node(CONS, "num", 'f', $1, $1, NULL, NULL, NULL); }
;

// expresion -> expr < expr
//            | expr > expr
//            | expr = expr
expresion : expr LESS expr                                                                                     { char c1 = check_types($1); if (c1 != check_types($3)) { yyerror("Invalid types between operation."); } $$ = new_tree_node(LESS, "<", c1, 0, 0.0, $1, $3, NULL); }
          | expr GREATER expr                                                                                  { char c1 = check_types($1); if (c1 != check_types($3)) { yyerror("Invalid types between operation."); } $$ = new_tree_node(GREATER, ">", c1, 0, 0.0, $1, $3, NULL); }
          | expr EQUAL expr                                                                                    { char c1 = check_types($1); if (c1 != check_types($3)) { yyerror("Invalid types between operation."); } $$ = new_tree_node(EQUAL, "=", c1, 0, 0.0, $1, $3, NULL); }
;

// End of grammar

%%


int yyerror(char const * s)
{
   fprintf(stderr, "Error near line %i: %s\n", line, s);
   exit(1);
}

int user_input_error(char const * s)
{
   fprintf(stderr, "Error: %s\n", s);
   exit(1);
}

void main(int argc, char *argv[])
{
   yyin = fopen(argv[1], "r");

   init_table();
   yyparse();
   //print_table();
   check_tree(tree);
   exit(0);
}

// Create new tree node
ASR * new_tree_node(int node_type, unsigned char name[], char value_type, int int_value, float float_value, ASR * left, ASR * right, ASR * next)
{
   ASR * aux = (ASR *) malloc(sizeof(ASR)); // ASR type node
   aux -> node_type = node_type;
   strcpy(aux -> name, name);
   aux -> value_type = value_type;
   aux -> int_value = int_value;
   aux -> float_value = float_value;
   aux -> left = left;
   aux -> right = right;
   aux -> next = next;
   
   return aux;
}

// Create new list node
LST * new_list_node(unsigned char name[], int type, LST * next)
{
   LST * aux = (LST *) malloc(sizeof(LST)); // LST type node
   strcpy(aux -> name, name);
   aux -> value_type = type;
   aux -> next = next;
   
   return aux;
}

// Create new hash table node
SYM * new_table_node(unsigned char name[], int type)
{
   SYM * aux = (SYM *) malloc(sizeof(SYM)); // SYM type node
   strcpy(aux -> name, name);
   aux -> value_type = type;
   
   return aux;
}

// Insert new hash table node
void insert_table_node(SYM *t)
{
   unsigned int index = hash(t -> name);
   if (table[index] == NULL) { table[index] = t; }
   else
   {
      SYM *n = table[index];
      while (n -> next != NULL) { n = n -> next; } // Iterate list
      n -> next = t;
   }
}

// Get last element of a list
LST * get_list_tail(LST * head)
{
   LST *n = head;
   while (n -> next != NULL) { n = n -> next; } // Iterate list
   
   return n; // Last node of the list
}

// Assign variable type
void assign_type(LST * head, int type)
{
   LST *n = head;
   while (n != NULL) // Iterate list
   {
      SYM *t = search_symbol(n -> name);
      t -> value_type = type;
      n = n -> next;
   }
}

// Search variable in the hash table
SYM * search_symbol(unsigned char name[])
{
   SYM *n = table[hash(name)]; // Get the position of the symbol in the table
   while (n != NULL) // Iterate list
   {
      if (strcmp(n -> name, name) == 0) { return n; } // Symbol found
      n = n -> next;
   }
   
   return NULL; // Symbol not found
}

// Validate variable types
char check_types(ASR * root)
{
   ASR *n = root;
   if (n -> node_type == CONS) { return n -> value_type; } // Constant
   else if (n -> node_type == VAR) { return search_symbol(n -> name) -> value_type; } // Variable
   char a = check_types(n -> left); // Check left child nodes
   char b = check_types(n -> right); // Check right child nodes
   if (a == b) { return a; } // Same types
   else { yyerror("Invalid types between operation"); } // Different types
}

//Execute tree nodes actions
void check_tree(ASR * root)
{   
   ASR *parent = root; // ; node

   // NULL
   if (parent == NULL) { return; }

   // BLOCK
   if (parent -> node_type == BLOCK)
   {   
      ASR *n = parent -> left; // Child nodes

      // EQUIVAL
      if (n -> node_type == EQUIVAL)
      {
         SYM *t = search_symbol(n -> left -> name); // Get variable from the symbol table
         if (t -> value_type == 'i') { t -> int_value = expr_int_value(n -> right); } // Int value
         else { t -> float_value = expr_float_value(n -> right); } // Float value
      }
      
      // DO-IF
      if (n -> node_type == DO_IF)
      {
         char * op = n -> left -> name; // =, > or <
         if (expr_value_type(n -> left) == 'i') // Int type
         {
            int l_expr = expr_int_value(n -> left -> left); // Left expr
            int r_expr = expr_int_value(n -> left -> right); // Right expr
            if (strcmp(op, "=") == 0) { if (l_expr == r_expr) { check_tree(n -> right); } } // =
            else if (strcmp(op, ">") == 0) { if (l_expr > r_expr) { check_tree(n -> right); } } // >
            else if (strcmp(op, "<") == 0) { if (l_expr < r_expr) { check_tree(n -> right); } } // <
         }
         else // Float type
         {
            float l_expr = expr_float_value(n -> left -> left); // Left expr
            float r_expr = expr_float_value(n -> left -> right); // Right expr
            if (strcmp(op, "=") == 0) { if (l_expr == r_expr) { check_tree(n -> right); } } // =
            else if (strcmp(op, ">") == 0) { if (l_expr > r_expr) { check_tree(n -> right); } } // >
            else if (strcmp(op, "<") == 0) { if (l_expr < r_expr) { check_tree(n -> right); } } // <
         }
      }

      // DO-IF-ELSE
      if (n -> node_type == DO_IF_ELSE)
      {
         char * op = n -> left -> name; // =, > or <
         if (expr_value_type(n -> left) == 'i') // Int type
         {
            int l_expr = expr_int_value(n -> left -> left); // Left expr
            int r_expr = expr_int_value(n -> left -> right); // Right expr
            if (strcmp(op, "=") == 0) { if (l_expr == r_expr) { check_tree(n -> right); } else { check_tree(n -> next); } } // =
            else if (strcmp(op, ">") == 0) { if (l_expr > r_expr) { check_tree(n -> right); } else { check_tree(n -> next); } } // >
            else if (strcmp(op, "<") == 0) { if (l_expr < r_expr) { check_tree(n -> right); } else { check_tree(n -> next); } } // <
         }
         else // Float type
         {
            float l_expr = expr_float_value(n -> left -> left); // Left expr
            float r_expr = expr_float_value(n -> left -> right); // Right expr
            if (strcmp(op, "=") == 0) { if (l_expr == r_expr) { check_tree(n -> right); } else { check_tree(n -> next); } } // =
            else if (strcmp(op, ">") == 0) { if (l_expr > r_expr) { check_tree(n -> right); } else { check_tree(n -> next); } } // >
            else if (strcmp(op, "<") == 0) { if (l_expr < r_expr) { check_tree(n -> right); } else { check_tree(n -> next); } } // <
         }
      }

      // DO-UNTIL
      if (n -> node_type == DO_UNTIL)
      {
         char * op = n -> next -> name; // =, > or <
         if (expr_value_type(n -> next) == 'i') // Int type
         {
            int l_expr = expr_int_value(n -> next -> left); // Left expr
            int r_expr = expr_int_value(n -> next -> right); // Right expr
            if (strcmp(op, "=") == 0) // =
            {
               do { check_tree(n -> left); l_expr = expr_int_value(n -> next -> left); r_expr = expr_int_value(n -> next -> right); } // Perform action
               while (l_expr != r_expr); // Check condition
            }
            else if (strcmp(op, ">") == 0) // >
            {
               do { check_tree(n -> left); l_expr = expr_int_value(n -> next -> left); r_expr = expr_int_value(n -> next -> right); } // Perform action
               while (l_expr <= r_expr); // Check condition
            }
            else if (strcmp(op, "<") == 0) // <
            {
               do { check_tree(n -> left); l_expr = expr_int_value(n -> next -> left); r_expr = expr_int_value(n -> next -> right); } // Perform action
               while (l_expr >= r_expr); // Check condition
            }
         }
         else // Float type
         {
            float l_expr = expr_float_value(n -> next -> left); // Left expr
            float r_expr = expr_float_value(n -> next -> right); // Right expr
            if (strcmp(op, "=") == 0) // =
            {
               do { check_tree(n -> left); l_expr = expr_float_value(n -> next -> left); r_expr = expr_float_value(n -> next -> right); } // Perform action
               while (l_expr != r_expr); // Check condition
            }
            else if (strcmp(op, ">") == 0) // >
            {
               do { check_tree(n -> left); l_expr = expr_float_value(n -> next -> left); r_expr = expr_float_value(n -> next -> right); } // Perform action
               while (l_expr <= r_expr); // Check condition
            }
            else if (strcmp(op, "<") == 0) // <
            {
               do { check_tree(n -> left); l_expr = expr_float_value(n -> next -> left); r_expr = expr_float_value(n -> next -> right); } // Perform action
               while (l_expr >= r_expr); // Check condition
            }
         }
      }

      // DO-WHILE
      if (n -> node_type == DO_WHILE)
      {
         char * op = n -> next -> name; // =, > or <
         if (expr_value_type(n -> next) == 'i') // Int type
         {
            int l_expr = expr_int_value(n -> next -> left); // Left expr
            int r_expr = expr_int_value(n -> next -> right); // Right expr
            if (strcmp(op, "=") == 0) // =
            {
              printf("Yes");
               do { check_tree(n -> left); l_expr = expr_int_value(n -> next -> left); r_expr = expr_int_value(n -> next -> right); } // Perform action
               while (l_expr == r_expr); // Check condition
            }
            else if (strcmp(op, ">") == 0) // >
            {
               do { check_tree(n -> left); l_expr = expr_int_value(n -> next -> left); r_expr = expr_int_value(n -> next -> right); } // Perform action
               while (l_expr > r_expr); // Check condition
            }
            else if (strcmp(op, "<") == 0) // <
            {
               do { check_tree(n -> left); l_expr = expr_int_value(n -> next -> left); r_expr = expr_int_value(n -> next -> right); } // Perform action
               while (l_expr < r_expr); // Check condition
            }
         }
         else // Float type
         {
            float l_expr = expr_float_value(n -> next -> left); // Left expr
            float r_expr = expr_float_value(n -> next -> right); // Right expr
            if (strcmp(op, "=") == 0) // =
            {
               do { check_tree(n -> left); l_expr = expr_float_value(n -> next -> left); r_expr = expr_float_value(n -> next -> right); } // Perform action
               while (l_expr == r_expr); // Check condition
            }
            else if (strcmp(op, ">") == 0) // >
            {
               do { check_tree(n -> left); l_expr = expr_float_value(n -> next -> left); r_expr = expr_float_value(n -> next -> right); } // Perform action
               while (l_expr > r_expr); // Check condition
            }
            else if (strcmp(op, "<") == 0) // <
            {
               do { check_tree(n -> left); l_expr = expr_float_value(n -> next -> left); r_expr = expr_float_value(n -> next -> right); } // Perform action
               while (l_expr < r_expr); // Check condition
            }
         }
      }

      // PRINT
      if (n -> node_type == PRINT)
      {
         if (expr_value_type(n -> left) == 'i') { printf("%i\n", expr_int_value(n -> left)); } // Int type
         else { printf("%f\n", expr_float_value(n -> left)); } // Float type
      }

      // READ
      if (n -> node_type == READ)
      {
         SYM *t = search_symbol(n -> left -> name); // Get variable from the symbol table
         if (expr_value_type(n -> left) == 'i') { if (scanf("%i", &(t -> int_value)) != 1) { user_input_error("Invalid type.");} } // Int type
         else { scanf("%f", &(t -> float_value)); } // Float type
      }
   }
   check_tree(parent -> next);
}

// Return int result of expr
int expr_int_value(ASR * root)
{
   int aux1, aux2;
   if (root == NULL) return 0;
   if (root -> node_type == SUM || root -> node_type == SUBSTRACT || root -> node_type == MULTI || root -> node_type == DIVIDE)
   {
      aux1 = expr_int_value(root -> left); // Left expr
      aux2 = expr_int_value(root -> right); // Right expr
      if (root -> node_type == SUM) { return aux1 + aux2; } // +
      if (root -> node_type == SUBSTRACT) { return aux1 - aux2; } // -
      if (root -> node_type == MULTI) { return aux1 * aux2; } // *
      if (root -> node_type == DIVIDE) { return aux1 / aux2; } // /
   }
   else if (root -> node_type == CONS) { return root -> int_value; } // Constant
   else if (root -> node_type == VAR) { return search_symbol(root -> name) -> int_value; } // Variable
}

// Return float result of expr
float expr_float_value(ASR * root)
{
   float aux1, aux2;
   if (root == NULL) return 0.0;
   if (root -> node_type == SUM || root -> node_type == SUBSTRACT || root -> node_type == MULTI || root -> node_type == DIVIDE)
   {
      aux1 = expr_float_value(root -> left); // Left expr
      aux2 = expr_float_value(root -> right); // Right expr
      if (root -> node_type == SUM) { return aux1 + aux2; } // +
      if (root -> node_type == SUBSTRACT) { return aux1 - aux2; } // -
      if (root -> node_type == MULTI) { return aux1 * aux2; } // *
      if (root -> node_type == DIVIDE) { return aux1 / aux2; } // /
   }
   else if (root -> node_type == CONS) { return root -> float_value; } // Constant
   else if (root -> node_type == VAR) { return search_symbol(root -> name) -> float_value; } // Variable
}

// Return value type of expr
char expr_value_type(ASR * root)
{
   if (root == NULL) return '0';
   if (root -> node_type == VAR) { return search_symbol(root -> name) -> value_type; } // Look at the symbol table for the symbol's value type
   else { return root -> value_type; }
}

// Initialize the hash table pointers to NULL
void init_table()
{
    for (int i = 0; i < N; i++) { table[i] = NULL; } // Iterate array
}

// Hash word to a number
unsigned int hash(unsigned char word[])
{
    // sdbm
    // This algorithm was created for sdbm
    // (a public-domain reimplementation of ndbm) database library
    // Source: http://www.cse.yorku.ca/~oz/hash.html

    unsigned int hash = 0;
    int c;
    while ((c = *word++)) { hash = c + (hash << 6) + (hash << 16) - hash; }

    return hash % N;
}

// Print tree content
void print_tree(ASR * raiz, int lines)
{   
   ASR *n = raiz;
   if (n == NULL) { return; }
   for (int i = 0; i < lines; i++) { printf("\t"); } // Add tab
   printf("[%i, %s, %c, %i, %f]\n", n -> node_type, n -> name, n -> value_type, n -> int_value, n -> float_value); // Content
   print_tree(n -> left, lines + 1); // Left side
   print_tree(n -> right, lines + 1); // Right side
   print_tree(n -> next, lines); // Next neighbor node
}

// Print list content
void print_list(LST * head)
{
   LST *n = head;
   if (n == NULL) { return; }
   printf("[%s, %c]\n", n -> name, n -> value_type); // Content
   print_list(n -> next); // Next node of list
}

// Print symbol table content
void print_table()
{
   printf("table:\n");
   for (int i = 0; i < N; i++) // Iterate array
   {
      SYM *n = table[i];
      while (n != NULL) // Iterate list
      {
         printf("variable: %s, %c, %i, %f\n", n -> name, n -> value_type, n -> int_value, n -> float_value); // Content
         n = n-> next;
      }
   }
   printf("\n");
}
