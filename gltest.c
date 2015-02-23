#include <stdlib.h>
#include <OpenGL/gl.h>
#include <GLUT/glut.h>
#include "prelude.h"
void paint() {
  glClearColor(0.3,0.3,0.3,0.0);
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  glShadeModel(GL_SMOOTH);
  glLoadIdentity();
  glTranslatef(-15.0,-15.0,0.0);
  glBegin(GL_TRIANGLES);
  glColor3f(1.0,0.0,0.0);
  glVertex2f(0.0,0.0);
  glColor3f(0.0,1.0,0.0);
  glVertex2f(30.0,0.0);
  glColor3f(0.0,0.0,1.0);
  glVertex2f(0.0,30.0);
  glEnd();
  glFlush();
; }
void reshape(int a0, int a1) {
int height = a1;
int width = a0;
  glViewport(0,0,width,height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(-30.0,30.0,-30.0,30.0,-30.0,30.0);
  glMatrixMode(GL_MODELVIEW);
; }
int main(int argc, char **argv) {  
glutInit(&argc,argv);
glutInitWindowSize(640,480);
glutCreateWindow("Triangle");
glutDisplayFunc(paint);
glutReshapeFunc(reshape);
glutMainLoop();
}

