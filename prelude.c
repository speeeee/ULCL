#include <stdlib.h>
#include <stdio.h>
int add(int a0, int a1) {
return a1+a0;
; }
int sub(int a0, int a1) {
return a1-a0;
; }
int ti(int a0, int a1) {
return a1*a0;
; }
int div(int a0, int a1) {
return a1/a0;
; }
bool equ(int a0, int a1) {
return a1==a0;
; }
bool les(int a0, int a1) {
return a1<a0;
; }
bool grt(int a0, int a1) {
return a1>a0;
; }
void* nth(int a0, int* a1) {
return a1[a0];
; }

