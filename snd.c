// cc -I/usr/include/SDL snd.c -lSDL -o s && ./s

#include <math.h>
#include <SDL.h>

struct {
	int ptr, left;
	float p, dp;
	float	e, de;
} wave;

float ntf;

int seq[] = {1, 6, 8, 11, 1, 6, 8, 15};
int seq_len[] = {2, 4, 4,  2, 2, 4, 4,  2};

#define CBUFSZ 16384

float outbuf[CBUFSZ];
int outbufpos;
float convbuf[CBUFSZ];

#define PRESIZE (44100*10)

float prebuf[PRESIZE];
int prepos;

void playback(void *userdata, Uint8 *stream, int len)
{
	memcpy(stream, prebuf+prepos, len);
	prepos += len / 2;
	if (prepos > (PRESIZE - len/2))
	{
			exit(0);
	}
}

void generate(void *userdata, Uint8 *stream, int len)
{
	short* p = (short*)stream;
	int i;
	len/=2;
	for(i = 0; i < len; ++i)
	{
		if (wave.left == 0)
		{
			wave.left = 44100. / seq_len[wave.ptr];
			wave.dp = 2. * M_PI* 440. * pow(ntf, seq[wave.ptr]) / 44100.;
			wave.de = (M_PI / 0.06) / 44100.;
			wave.e = 0.;
			wave.ptr++;
			wave.ptr&=7;
		}

		wave.left--;
		wave.p += wave.dp;
		wave.e += wave.de;
		if (wave.e >= M_PI) wave.de = 0.;
		float s = 0.5 * sin(wave.e) * sin(wave.p);

		int j;
	/*	for(j = 0; j < CBUFSZ; ++j)
		{
				s += convbuf[j] * outbuf[(outbufpos-j)&(CBUFSZ-1)];
		}*/

		*p++ = s * 32767.;

//		outbuf[outbufpos] = s;

	//	outbufpos++;
		//outbufpos &= CBUFSZ-1;
	}
}

SDL_AudioSpec as = {44100, 0x8010, 1, 0, 0, 0, 0, generate}; //playback};

void main(void)
{
	memset(&wave,0,sizeof(wave));
	ntf = pow(2., 1./12.);
//	convbuf[11050] = 0.5;
//	generate(0,prebuf,PRESIZE*2);

	SDL_Init(SDL_INIT_AUDIO|SDL_INIT_VIDEO);
	SDL_SetVideoMode(640,480,32,0);
	SDL_OpenAudio(&as, 0);
	SDL_PauseAudio(0);
	for(;;)
	{
		SDL_Event e;
		SDL_WaitEvent(&e);
		if (e.type == 2) break;
	}
	SDL_Quit();
}
