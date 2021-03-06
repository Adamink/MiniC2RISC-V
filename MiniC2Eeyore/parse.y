%{
#include "util.h"
#include "node.h"
#include "type.h"
#include "env.h"

using namespace std;
%}
/* generate include-file with symbols and types */
%locations
//%define api.location.file "parse.h"
// 

/* a more advanced semantic type */
%union {
    int ival;
    char* sval;
    Node* nval;
}
%token <ival> TYPE INTEGER PLUS MINUS TIME DIVIDE MOD NOT AND OR LESS GREATER
 EQUAL NOTEQUAL ASSIGN IF ELSE WHILE RETURN MAIN DOUBLEPLUS DOUBLEMINUS
%token <sval> '(' ')' '[' ']' '{' '}' ';' ',' ID
%type <nval> Program GlobalList FuncDecl VarDefn FuncDefn Blocks Block 
 Statement ParaList ParaDecls ParaDecl ExprList Expressions Expression

%nonassoc IF
%nonassoc ELSE
%right RETURN
%right ASSIGN
%left OR
%left AND
%left EQUAL NOTEQUAL
%left LESS GREATER
%left PLUS MINUS
%left TIME DIVIDE MOD
%right NOT UMINUS DOUBLEPLUS DOUBLEMINUS

%start Program
%%
Program:    
    GlobalList
    {
            debugging("finish parsing\n");
            RootNode* ret = new RootNode();
            ret->addChild($1);
            ret->finishParsing();
            $$ = (Node*)ret;
    }
    ;
GlobalList:
    VarDefn GlobalList
    {
        Node* ret = new OtherNode();
        ret->addChild($1);
        ret->addChild($2);
        $$ = ret;
    }
    |
    FuncDefn 
    {
        debugging("reducin to FuncDefn\n");
    }
    GlobalList
    {
        Node* ret = new OtherNode();
        ret->addChild($1);
        ret->addChild($3);
        $$ = ret;
    }
    |
    FuncDecl GlobalList
    {
        Node* ret = new OtherNode();
        ret->addChild($1);
        ret->addChild($2);
        $$ = ret;
    }
    |
    /* empty */
    {
        $$ = new EmptyNode();
    }
    |
    error 
    {
        string errMsg = 
        "your code is such a mess that compiler" \
        " can't decide which part is wrong";
        printErrorInfo(errMsg, @1); // ?
        $$ = new EmptyNode();
    }
    ;
VarDefn:
    TYPE ID ';'
    {
        // this part could be added to createIdEntry
        createIdEntry($2, IntType, @2);
        string name = getIdName($2,@2);
        string code = "var " + name + "\n";
        Node* ret = new StatementNode();
        ret->appendCode(code);
        $$ = ret;
    }
    |
    TYPE ID '[' INTEGER ']' ';'
    {
        createIdEntry($2, ArrayType, @2);
        string name = getIdName($2,@2);
        string code = "var " + to_string(4*$4) + " " + name + "\n";
        Node* ret = new StatementNode();
        ret->appendCode(code);
        $$ = ret;
    }
    |
    error ';'
    {
        printErrorInfo("wrong variable definition method", @2);
        $$ = new StatementNode();
    }
    ;
// used only in FuncDecl
ParaDecl:
    TYPE ID
    {
        Node* ret = new ParaNode($2,IntType);
        $$ = ret;
    }
    |
    TYPE ID '[' INTEGER ']'
    {
        Node* ret = new ParaNode($2,ArrayType);
        $$ = ret;
    }
    |
    TYPE ID '[' ']'
    {
        Node* ret = new ParaNode($2,ArrayType);
        $$ = ret;
    }
    |
    TYPE
    {
        Node* ret = new ParaNode(IntType);
        $$ = ret;
    }
    |
    TYPE '[' ']'
    {
        Node* ret = new ParaNode(ArrayType);
        $$ = ret;
    }
    ;
// one or more ParaDecl, seperated by ','
ParaDecls:
    ParaDecl
    {
        Node* ret = new ParaListNode();
        ret->addChild($1);
        $$ = ret;
    }
    |
    ParaDecl ',' ParaDecls
    {
        Node* ret = new ParaListNode();
        ret->addChild($1);
        ret->addChild($3);
        $$ = ret;
    }
    ;
// empty or one or more ParaDecl, seprated by ','
ParaList:
    ParaDecls
    {
        $$ = $1;
    }
    |
    /* empty */
    {
        $$ = new ParaListNode();
    }
    ;
FuncDecl:
    TYPE ID '(' ParaList ')' ';'
    {
        Node* ret = new FuncNode();
        string name = string($2);
        createFuncEntry(name, DeclType, (ParaListNode*)$4, @2);
        $$ = ret;
    }
    |
    error ';'
    {
        printErrorInfo("wrong function declare method", @2);
        $$ = new FuncNode();
    }
    ;
FuncDefn:
    TYPE ID '(' ParaList ')' '{'
    {
    /*
    * check func's compatability with previous ones
    * if ok, insert funcEntry to funcTable for future check
    * if also FuncDefn insert paraList to idTable and newScope()
    */
        string name = string($2);
        createFuncEntry(name, DefnType,(ParaListNode*)$4, @2);
    }
    Blocks '}' 
    {
        debugging("reducing blocks to FuncDefn\n");
        Node* ret = new FuncNode();
        ret->addChild($8);
        int paraNum; //= getParaNum((ParaListNode*)$4);
        FuncEntry* f = findFuncEntry($2, @2);
        if(f==NULL) debugging("func should be defined\n");
        paraNum = f->paraList.size();
        string codeBefore = "f_" + string($2) + " [" +to_string(paraNum)
         + "]\n";
        string codeAfter;

        // add return automatically
        if(!hasReturn)
            codeAfter = "return 0\nend f_" + string($2) + "\n";
        else
            codeAfter = "end f_" + string($2) +"\n";
        ret->appendCodeBefore(codeBefore);
        ret->appendCodeAfter(codeAfter);
        $$ = ret;

        // exit func, endScope(), reset funcName
        exitFunc();
    }
    ;
// a block that can be seen as one statement
Block:
    Statement
    {
        Node* ret = new OtherNode();
        ret->addChild($1);
        $$ = ret;
        debugging("reducing statement to block");
    }
    |
    '{' {newScope();} Blocks '}'
    {
        endScope();
        $$ = $3;
    }
    |
    IF '(' Expression ')' Block
    {
        Node* ret = new OtherNode();
        ret->addChild($3);
        ret->addChild($5);
        string l = newLabel();
        string jmpCode = 
        "if " + ((ExprNode*)$3)->valueID + " == 0 goto " + l + "\n";
        ret->appendCodeMiddle(jmpCode);
        ret->appendCodeAfter(l + ":\n");
        $$ = ret;
    } %prec IF
    |
    IF '(' Expression ')' Block ELSE Block
    {
        Node* midNode = new OtherNode();
        midNode->addChild($5);
        midNode->addChild($7);
        Node* ret = new OtherNode();
        ret->addChild($3);
        ret->addChild(midNode);
        $$ = ret;
        string l1 = newLabel();
        string l2 = newLabel();
        string jmp1 = 
        "if " + ((ExprNode*)$3)->valueID + " == 0 goto " + l1 + "\n";
        string jmp2 = "goto " + l2 + "\n";
        midNode->appendCodeBefore(jmp1);
        midNode->appendCodeMiddle(jmp2 + l1 + ":\n");
        midNode->appendCodeAfter(l2+":\n");
    } %prec ELSE
    |
    WHILE '(' Expression ')' Block
    {
        Node* ret = new OtherNode();
        ret->addChild($3);
        ret->addChild($5);
        string l1 = newLabel();
        string l2 = newLabel();
        string jmp1 = 
        "if " + ((ExprNode*)$3)->valueID + " == 0 goto " + l2 + "\n";
        string jmp2 = "goto " + l1 + "\n";
        ret->appendCodeBefore(l1 + ":\n");
        ret->appendCodeMiddle(jmp1);
        ret->appendCodeAfter(jmp2 + l2 + ":\n");
        $$ = ret;
    }
    ;
// continuous many blocks
Blocks:
    Block Blocks
    {
        Node* ret = new OtherNode();
        ret->addChild($1);
        ret->addChild($2);
        $$ = ret;
        debugging("reducing to blocks\n");
    }
    |
    /* empty */
    {
        Node* ret = new EmptyNode();
        $$ = ret;
    }
    ;
// literally a single statement
Statement:
    Expression ';'
    {
        $$ = $1;
    }
    |
    VarDefn
    {
        $$ = $1;
        debugging("reducing vardefn to statement");
    }
    |
    RETURN Expression ';'
    {
        Node* ret = new OtherNode();
        ret->addChild($2);
        $$ = ret;
        string s = "return " + ((ExprNode*)$2)->valueID + "\n";
        ret->appendCodeAfter(s);
        hasReturn = true;
    }
    |
    error ';'
    {
        $$ = new OtherNode();
        string errMsg = "broken statement";
        printErrorInfo(errMsg, @2);
    }
    ;
// zero or one or more expressions, seperated by ',' 
ExprList:
    Expressions 
    {
        Node* ret = new ExprListNode();
        ret->addChild($1);
        $$ = ret;
    }
    |
    /* empty */
    {
        Node* ret = new ExprListNode();
        $$ = ret;
    }
    ;
// more than one expression, seperated by ','
Expressions:
    Expression ',' Expressions
    {
        Node* ret = new OtherNode();
        ret->addChild($1);
        ret->addChild($3);
        $$ = ret;
    }
    |
    Expression
    {
        $$ = $1;
    }
    ;
Expression:
    INTEGER
    {
        ExprNode* ret = new ExprNode();
        ret->isInteger = true;
        ret->valueID = to_string($1);
        $$ = (Node*)ret;
        debugging("reducing integer to Expression\n");
    }
    |
    ID
    {
        ExprNode* ret = new ExprNode();
        string name = string($1);
        ret->isID = true;
        ret->valueID = getIdName(name, @1);
        $$ = (Node*)ret;
    }
    |
    '(' Expression ')'
    {
        $$ = $2;
    }
    |
    Expression PLUS Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " + 
         ((ExprNode*)$1)->valueID + " + " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;           
    }
    |
    Expression MINUS Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " + 
         ((ExprNode*)$1)->valueID + " - " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;    
        debugging("reduce to MINUS Expression\n");       
    }
    |
    MINUS Expression %prec UMINUS
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($2);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = -" +
         ((ExprNode*)$2)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;      
    }
    |
    Expression TIME Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " +
         ((ExprNode*)$1)->valueID + " * " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;           
    }
    |
    Expression DIVIDE Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " +
         ((ExprNode*)$1)->valueID + " / " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;      

        if(((ExprNode*)$3)->valueID=="0"){
            printWarningInfo("division by zero", @2);
        }
    }
    |
    Expression MOD Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " +
         ((ExprNode*)$1)->valueID + " % " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;      

        if(((ExprNode*)$3)->valueID=="0"){
            printWarningInfo("division by zero", @2);
        }
    }
    |
    Expression AND Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = "
         + ((ExprNode*)$1)->valueID + " && " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;      
    }
    |
    Expression OR Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " +
         ((ExprNode*)$1)->valueID + " || " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;   
    }
    |
    NOT Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($2);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = !" +
         ((ExprNode*)$2)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;
    }
    |
    Expression LESS Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " +
         ((ExprNode*)$1)->valueID + " < " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;      
    }
    |
    Expression GREATER Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " +
         ((ExprNode*)$1)->valueID + " > " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
        $$ = (Node*)ret;  
    }
    |
    Expression EQUAL Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        $$ = (Node*)ret;     

        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " +
         ((ExprNode*)$1)->valueID + " == " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
    }
    |
    Expression NOTEQUAL Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($1);
        ret->addChild($3);
        $$ = (Node*)ret;             

        string tmp = newTemp();
        string code = "var " + tmp + "\n" + tmp + " = " +
         ((ExprNode*)$1)->valueID + " != " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = tmp;
    }
    |
    ID '(' ExprList ')' 
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($3);
        $$ = (Node*)ret;
        string name = string($1);
        ExprListNode* exprList = (ExprListNode*)$3;
        FuncEntry call = FuncEntry(name, exprList);
        FuncEntry* called = findFuncEntry(name, @1);
        if(called!=NULL){
            int cmpParaNum = cmpFuncParaNum(call, *called);
            if(cmpParaNum > 0){
                string errMsg = "too many arguments to function '" + name + "'";
                printErrorInfo(errMsg,@1);
            }
            else if(cmpParaNum < 0){
                string errMsg = "too few arguments to function '" + name + "'";
                printErrorInfo(errMsg,@1);
            }
            else{
                // main branch
                stringstream code = stringstream();
                string tmp = newTemp();
                ret->valueID = tmp;
                code << "var " << tmp << endl;
                for(auto& para:call.paraList){
                    code << "param " << para.EName << endl;
                }
                code << tmp << " = call f_" << name << endl;
                ret->appendCodeAfter(code.str());
                ret->valueID = tmp;
            }
        }
        else{
            // warning but still do same thing as main branch
            stringstream code = stringstream();
            string tmp = newTemp();
            ret->valueID = tmp;
            code << "var " << tmp << endl;
            for(auto& para:call.paraList){
                code << "param " << para.EName << endl;
            }
            code << tmp << " = call f_" << name << endl;
            ret->appendCodeAfter(code.str());
            ret->valueID = tmp;
        }
    }
    |
    ID '[' Expression ']'
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($3);
        $$ = (Node*)ret;

        string CName = string($1);
        string EName = getIdName(CName, @1);
        string temp1 = newTemp();
        string temp2 = newTemp();
        string valueID = ((ExprNode*)$3)->valueID;
        string code;
        code = "var " + temp1 + "\n" + temp1 + " = 4 * " + valueID + "\n" +
         "var " + temp2 + "\n" + temp2 + " = " + EName + "[" + temp1 + "]" +
          "\n";
        ret->appendCodeAfter(code);
        ret->valueID = temp2;
    }
    |
    ID ASSIGN Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($3);
        $$ = (ExprNode*)ret;

        string CName = string($1);
        string EName = getIdName(CName,@1);
        string code;
        code = EName + " = " + ((ExprNode*)$3)->valueID + "\n";
        ret->appendCodeAfter(code);
        ret->valueID = EName;
    }
    |
    ID '[' Expression ']' ASSIGN Expression
    {
        ExprNode* ret = new ExprNode();
        ret->addChild($3);
        ret->addChild($6);
        $$ = ret;

        string CName = string($1);
        string EName = getIdName(CName,@1);
        // string temp2 = newTemp();
        stringstream code = stringstream();
        ExprNode* expr = (ExprNode*)$3;
        if(expr->isInteger){
            int bias = 4 * stoi(expr->valueID);
            code << EName << "[" << to_string(bias) << "] = " << ((ExprNode*)$6)->valueID << endl;
        }
        else{
            string temp1 = newTemp();
            code << "var " << temp1 << endl;
            code << temp1 << " = 4 * " << ((ExprNode*)$3)->valueID <<endl;
            // code << "var " << temp2 << endl;
            code << EName << "[" << temp1 << "] = " << ((ExprNode*)$6)->valueID << endl;
        }

        ret->appendCodeAfter(code.str());
        // ret->valueID = temp2;
        // ?
    }
    |
    DOUBLEPLUS ID
    {
        ExprNode* ret = new ExprNode();
        $$ = ret;

        string CName =string($2);
        string EName = getIdName(CName,@2);
        string code = EName + " = " + EName + " + 1\n";
        ret->appendCode(code);
        ret->valueID = EName; 
    }
    |
    ID DOUBLEPLUS
    {
        ExprNode* ret = new ExprNode();
        $$ = ret;

        string CName =string($1);
        string EName = getIdName(CName,@1);
        string temp = newTemp();
        stringstream code = stringstream();
        code << "var " << temp << endl;
        code << temp << " = " << EName << endl;
        code << EName << " = " << EName << " + 1" << endl;
        ret->appendCode(code.str());
        ret->valueID = temp;
    }
    |
    DOUBLEMINUS ID
    {
        ExprNode* ret = new ExprNode();
        $$ = ret;

        string CName =string($2);
        string EName = getIdName(CName,@2);
        string code = EName + " = " + EName + " - 1\n";
        ret->appendCode(code);
        ret->valueID = EName; 
    }
    |
    ID DOUBLEMINUS
    {
        ExprNode* ret = new ExprNode();
        $$ = ret;

        string CName =string($1);
        string EName = getIdName(CName,@1);
        string temp = newTemp();
        stringstream code = stringstream();
        code << "var " << temp << endl;
        code << temp << " = " << EName << endl;
        code << EName << " = " << EName << " - 1" << endl;
        ret->appendCode(code.str());
        ret->valueID = temp;
    }
    ;

%%
void yyerror(const char *s) {
    cerr << s;
}