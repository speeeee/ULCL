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
int equ(int a0, int a1) {
return a1==a0;
; }
int les(int a0, int a1) {
return a1<a0;
; }
int grt(int a0, int a1) {
return a1>a0;
; }
void* nth(int a0, int* a1) {
return a1[a0];
; }
int adr(int* a0) {
return &a0; }

