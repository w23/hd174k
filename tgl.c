/*
*    Description:  safe c-version of tgl.asm
*        Created:  08/29/2011 12:01:12 PM
*        Compile: cc -m32 -I/usr/include/SDL /usr/lib32/libSDL-1.2.so.0 -lGL tgl.c -o tgl-c && ./tgl-c
*
*        by w23 (me@w23.ru)
*/

#include <SDL.h>
#include <GL/gl.h>

#define W 1920
#define H 1080


char* shader_vtx[] = {
	"varying vec4 p;"
	"void main(){p=gl_Position=gl_Vertex;}"
};

char* shader_frg[] = {
	"uniform int t;"
	"varying vec4 p;"
	"void main(){"
		"float c,f=float(t)/5000.;"
		"vec2 s1,s2;"
		"s1=4.*vec2(sin(-f),cos(-f));"
		"s2=7.*vec2(sin(f*3.),cos(f*3.));"
		"c=sin(3.*p.x+s1.x)*sin(4.*p.y+s1.y)"
		"+sin(7.*p.x+s2.x)*sin(2.*p.y+s2.y);"
		"gl_FragColor="
		"vec4(sin(2.*(c+sqrt(c/4.))),c/4.+.5,log2(c)+exp(c),0.);"
	"}"
};

void shader(char** src, int type, int p)
{
	int s = glCreateShader(type);
	glShaderSource(s, 1, src, 0);
	glCompileShader(s);
	glAttachShader(p, s);
}

int main()
{
	SDL_Init(SDL_INIT_VIDEO);
	SDL_SetVideoMode(W, H, 32, SDL_OPENGL|SDL_FULLSCREEN);
	SDL_ShowCursor(0);

	glViewport(0,0,W,H);
	
	int p = glCreateProgram();
	shader(shader_vtx, GL_VERTEX_SHADER, p);
	shader(shader_frg, GL_FRAGMENT_SHADER, p);
	glLinkProgram(p);
	glUseProgram(p);

	int tloc = glGetUniformLocation(p, "t");

	SDL_Event e;
	for(;;)
	{
		if(SDL_PollEvent(&e) && e.type == 2) break;
		glUniform1i(tloc,SDL_GetTicks());
		glBegin(GL_QUADS);
		glVertex2f(-1,-1);
		glVertex2f(-1,1);
		glVertex2f(1,1);
		glVertex2f(1,-1);
		glEnd();
		SDL_GL_SwapBuffers();
	}
	SDL_Quit();
}
