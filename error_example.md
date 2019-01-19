## 使用未定义的变量

```c
int main(){
    a = 2;
    return 0;
}
```

```txt
test.c: In function ‘int main()’:
test.c:2:5: error: ‘a’ was not declared in this scope
     a = 2;
     ^
```

## 变量定义语法错误

```c
int main(){
    int a[;
    return 0;
}
```

Bug Report:

```tx

```

```c
int main(){
    int a[];
    return 0;
}
```

Bug Report:

```txt

```



## 变量重名

```c
#include<stdio.h>
int main(){
    int a = 2;
    int a = 3;
    return 0;
}
```

```txt
test.c: In function ‘main’:
test.c:4:9: error: redefinition of ‘a’
     int a = 3;
         ^
test.c:3:9: note: previous definition of ‘a’ was here
     int a = 2;
         ^
```

```c
#include<stdio.h>
int a = 2;
int a = 3;
int main(){
    return 0;
}
```

```txt
test.c:3:5: error: redefinition of ‘a’
 int a = 3;
     ^
test.c:2:5: note: previous definition of ‘a’ was here
 int a = 2;
     ^
```

## 缺少分号

## 缺少返回值

```C
#include <stdio.h>
int f(){}
int main(){
    int a = f();
    printf("%d\n",a);
}
```



## 函数重名

```c
#include<stdio.h>
void f(int a,int b){
    a + b;
}
void f(int c){
    c;
}
int main(){
    return 0;
}
```

```txt
test.c:5:6: error: conflicting types for ‘f’
 void f(int c){
      ^
test.c:2:6: note: previous definition of ‘f’ was here
 void f(int a,int b){
      ^'
```

## 参数传入数量错误

```c
#include<stdio.h>
void f(int a, int b){
    a+b;
}
int main(){
    int a ;
    f(a);
    return 0;
}
```

```txt
test.c: In function ‘main’:
test.c:7:5: error: too few arguments to function ‘f’
     f(a);
     ^
test.c:2:6: note: declared here
 void f(int a, int b){
      ^
```

```c
#include<stdio.h>
void f(int a, int b){
    a+b;
}
int main(){
    int a ;
    f(a,a,a);
    return 0;
}
```

```txt
test.c: In function ‘main’:
test.c:7:5: error: too many arguments to function ‘f’
     f(a,a,a);
     ^
test.c:2:6: note: declared here
 void f(int a, int b){
      ^
```

## 参数传入类型错误

```c
#include<stdio.h>
typedef struct{
    double a;
    int b;
} s;
void f(s a){
}
int main(){
    double a = 0.;
    f(a);
    return 0;
}
```

```txt
test.c: In function ‘main’:
test.c:11:7: error: incompatible type for argument 1 of ‘f’
     f(a);
       ^
test.c:6:6: note: expected ‘st {aka struct <anonymous>}’ but argument is of type ‘double’
 void f(st s){
      ^
```

## 调用未声明的函数

```c
#include<stdio.h>
int main(){
    f();
    return 0;
}
```

```txt
test.c: In function ‘main’:
test.c:3:5: warning: implicit declaration of function ‘f’ [-Wimplicit-function-declaration]
     f();
     ^
```



## 变量和关键字冲突?

## 函数定义和声明不同

```c
#include<stdio.h>
extern void f(int a);
void f(int a,int b){
    a + b;
}
int main(){
    return 0;
}
```

```txt
test.c:3:6: error: conflicting types for ‘f’
 void f(int a,int b){
      ^
test.c:2:13: note: previous declaration of ‘f’ was here
 extern void f(int a);
```

## 函数多次定义

```c
#include<stdio.h>
void f(int a,int b){
    a + b;
}
void f(int a, int b){
    a - b;
}
int main(){
    return 0;
}
```

```txt
test.c:5:6: error: redefinition of ‘f’
 void f(int a, int b){
      ^
test.c:2:6: note: previous definition of ‘f’ was here
 void f(int a,int b){
      ^
```

## 零除

```c
#include<stdio.h>
int main(){
    int a ;
    a = 1 / 0;
    return a;
}
```

```txt
test.c: In function ‘main’:
test.c:4:11: warning: division by zero [-Wdiv-by-zero]
     a = 1 / 0;
           ^
```

```c
#include<stdio.h>
int main(){
    int a ;
    a = 1 % 0;
    return 0;
}
```

```txt
test.c: In function ‘main’:
test.c:4:11: warning: division by zero [-Wdiv-by-zero]
     a = 1 % 0;
           ^
```
