//GROUP NAME: Leo Ho, Minh Tran
%{
#define WIDTH 640
#define HEIGHT 480

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_thread.h>

static SDL_Window* window;
static SDL_Renderer* rend;
static SDL_Texture* texture;
static SDL_Thread* background_id;
static SDL_Event event;
static int running = 1;
static const int PEN_EVENT = SDL_USEREVENT + 1;
static const int DRAW_EVENT = SDL_USEREVENT + 2;
static const int COLOR_EVENT = SDL_USEREVENT + 3;

typedef struct color_t {
	unsigned char r;
	unsigned char g;
	unsigned char b;
} color;

typedef struct coord_t {
	float x;
	float y;
	float alpha;

} coords;

static coords current_coords;
static color current_color;
static double x = WIDTH / 2;
static double y = HEIGHT / 2;
static int pen_state = 1;
static double direction = 0.0;
static float var_table[26];

int yylex(void);
int yyerror(const char* s);
void startup();
int run(void* data);
void prompt();
void penup();
void pendown();
void move(int num);
void turn(int dir);
void output(const char* s);
void change_color(int r, int g, int b);
void clear();
void save(const char* path);
void shutdown();
void storeVariable(char var, float val);
float getVariable(char var);
void go_to(float x, float y);
void where();

%}

%union {
	float f;
	char* s;
	char c;
}

%locations

%token EQUAL
%token SEP
%token PENUP
%token PENDOWN
%token PRINT
%token CHANGE_COLOR
%token COLOR
%token CLEAR
%token TURN
%token LOOP
%token MOVE
%token GOTO
%token WHERE
%token NUMBER
%token END
%token SAVE
%token PLUS SUB MULT DIV
%token<s> STRING QSTRING
%token VAR
%type<f> expression expression_list NUMBER piority value
%type<c> VAR

%%

program:		statement_list END								{ printf("Program complete."); shutdown(); exit(0); }
		;
statement_list:	statement					
		|		statement statement_list
		;
statement:		command SEP										{ prompt(); }
		|		error '\n'										{ yyerrok; prompt(); }
		;
command:		PENUP											{ penup(); }
		|		PENDOWN											{ pendown(); }
		|		PRINT QSTRING									{ output((char*)$2); }
		|		SAVE STRING										{ save((char*)$2); }
		|		CHANGE_COLOR value value value					{ change_color((int)$2, (int)$3, (int)$4); }
		|		CLEAR											{ clear(); }
		|		TURN value										{ turn((int)$2); }
		|		MOVE value										{ move((int)$2); }
		|		GOTO value value								{ go_to($2, $3); }
		|		WHERE											{ where(); }
		|		expression_list
		| 		VAR EQUAL value									{storeVariable((char)$1, $3); printf("Variable assigned.\n"); }			
		;
expression_list:	expression				   	{ $$ = $1; if ($$ - (int)$$ == 0) printf("Result: %d\n", (int)$$); else printf("Result: %.1f\n", $$);}// Complete these and any missing rules
		|			expression expression_list	
		;
expression:	expression PLUS piority   	{ $$ = $1 + $3;}
		|	expression SUB piority		{ $$ = $1 - $3;}
		|	piority						{ $$ = $1;}
		;
piority:	piority MULT value		{ $$ = $1 * $3;}
		|	piority DIV value		{ $$ = $1 / $3;}
		|	value					{ $$ = $1;}
		;
value:		NUMBER					{ $$ = $1;}
		|	VAR						{ $$ = getVariable($1);}
		;

%%

int main(int argc, char** argv){
	startup();
	return 0;
}

int yyerror(const char* s){
	printf("Error: %s\n", s);
	return -1;
};

void prompt(){
	printf("gv_logo > ");
}

void penup(){
	event.type = PEN_EVENT;		
	event.user.code = 0;
	SDL_PushEvent(&event);
}

void pendown() {
	event.type = PEN_EVENT;		
	event.user.code = 1;
	SDL_PushEvent(&event);
}

void move(int num){
	coords prev_coords = current_coords;
	double radians = prev_coords.alpha * (M_PI / 180.0);
	current_coords.x = round(prev_coords.x + num * cos(radians));
	current_coords.y = round(prev_coords.y + num * sin(radians));
	event.type = DRAW_EVENT;
	event.user.code = 1;
	event.user.data1 = num;
	SDL_PushEvent(&event);
}

void turn(int dir){
	event.type = PEN_EVENT;
	event.user.code = 2;
	event.user.data1 = dir;
	SDL_PushEvent(&event);
	current_coords.alpha += dir;
}

void output(const char* s){
	printf("%s\n", s);
}

void change_color(int r, int g, int b){
	event.type = COLOR_EVENT;
	current_color.r = r;
	current_color.g = g;
	current_color.b = b;
	SDL_PushEvent(&event);
}

void clear(){
	event.type = DRAW_EVENT;
	event.user.code = 2;
	SDL_PushEvent(&event);
}

void go_to(float x, float y) {
	// Change current coordinates
    coords prev_coords = current_coords;
    current_coords.x = x;
    current_coords.y = y;

    // Calculate change in x and y
    float delta_x = current_coords.x - prev_coords.x;
    float delta_y = current_coords.y - prev_coords.y;

    // Calculate the distance to move
    double distance = sqrt(delta_x * delta_x + delta_y * delta_y);

    // Calculate the angle to turn
    double angle = atan2(delta_y, delta_x) * 180.0 / M_PI;

    // Turn the turtle
    turn(angle);
	current_coords.alpha = angle;
    // Draw if pen is down
    printf("Drawing line from (%f, %f) to (%f, %f)\n", prev_coords.x, prev_coords.y, current_coords.x, current_coords.y);
    // Move the turtle
    event.type = DRAW_EVENT;
	event.user.code = 1;
	event.user.data1 = (int)distance;
	SDL_PushEvent(&event);
}

void where() {
	printf("Current coordinates: (%f, %f)\n", current_coords.x, current_coords.y);
}

void storeVariable(char var, float val) {
    var_table[var] = val;
}

float getVariable(char var) {
	return var_table[var];
}

void startup(){
	SDL_Init(SDL_INIT_VIDEO);
	window = SDL_CreateWindow("GV-Logo", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
	if (window == NULL){
		yyerror("Can't create SDL window.\n");
	}
	
	//rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE);
	rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE | SDL_RENDERER_TARGETTEXTURE);
	SDL_SetRenderDrawBlendMode(rend, SDL_BLENDMODE_BLEND);
	texture = SDL_CreateTexture(rend, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, WIDTH, HEIGHT);
	if(texture == NULL){
		printf("Texture NULL.\n");
		exit(1);
	}
	SDL_SetRenderTarget(rend, texture);
	SDL_RenderSetScale(rend, 3.0, 3.0);

	background_id = SDL_CreateThread(run, "Parser thread", (void*)NULL);
	if(background_id == NULL){
		yyerror("Can't create thread.");
	}
	while(running){
		SDL_Event e;
		while( SDL_PollEvent(&e) ){
			if(e.type == SDL_QUIT){
				running = 0;
			}
			if(e.type == PEN_EVENT){
				if(e.user.code == 2){
					double degrees = ((int)e.user.data1) * M_PI / 180.0;
					direction += degrees;
				}
				if(e.user.code == 0) {
					pen_state = 0;
				}
				if(e.user.code == 1) {
					pen_state = 1;
				}
			}
			if(e.type == DRAW_EVENT){
				if(e.user.code == 1){
					int num = (int)event.user.data1;
					double x2 = x + num * cos(direction);
					double y2 = y + num * sin(direction);
					if(pen_state != 0){
						SDL_SetRenderTarget(rend, texture);
						SDL_RenderDrawLine(rend, x, y, x2, y2);
						SDL_SetRenderTarget(rend, NULL);
						SDL_RenderCopy(rend, texture, NULL, NULL);
					}
					x = x2;
					y = y2;
				} else if(e.user.code == 2){
					SDL_SetRenderTarget(rend, texture);
					SDL_RenderClear(rend);
					SDL_SetTextureColorMod(texture, current_color.r, current_color.g, current_color.b);
					SDL_SetRenderTarget(rend, NULL);
					SDL_RenderClear(rend);
				}
			}
			if(e.type == COLOR_EVENT){
				SDL_SetRenderTarget(rend, NULL);
				SDL_SetRenderDrawColor(rend, current_color.r, current_color.g, current_color.b, 255);
			}
			if(e.type == SDL_KEYDOWN){
			}

		}
		//SDL_RenderClear(rend);
		SDL_RenderPresent(rend);
		SDL_Delay(1000 / 60);
	}
}

int run(void* data){
	prompt();
	yyparse();
}

void shutdown(){
	running = 0;
	SDL_WaitThread(background_id, NULL);
	SDL_DestroyWindow(window);
	SDL_Quit();
}

void save(const char* path){
	SDL_Surface *surface = SDL_CreateRGBSurface(0, WIDTH, HEIGHT, 32, 0, 0, 0, 0);
	SDL_RenderReadPixels(rend, NULL, SDL_PIXELFORMAT_ARGB8888, surface->pixels, surface->pitch);
	SDL_SaveBMP(surface, path);
	SDL_FreeSurface(surface);
}
