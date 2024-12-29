//
//  NOTE sokol: all IO functions have been removed
//
// Copyright (c) 2009-2013 Mikko Mononen memon@inside.org
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
// 1. The origin of this software must not be misrepresented; you must not
//	claim that you wrote the original software. If you use this software
//	in a product, an acknowledgment in the product documentation would be
//	appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//	misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//

#define FONTSTASH_INCLUDED (1)
#define FONS_DEF_API
#define FONTSTASH_API_DECL FONS_DEF_API

#define FONS_INVALID -1

enum FONSflags {
	FONS_ZERO_TOPLEFT = 1,
	FONS_ZERO_BOTTOMLEFT = 2,
};

enum FONSalign {
	// Horizontal align
	FONS_ALIGN_LEFT 	= 1<<0,	// Default
	FONS_ALIGN_CENTER 	= 1<<1,
	FONS_ALIGN_RIGHT 	= 1<<2,
	// Vertical align
	FONS_ALIGN_TOP 		= 1<<3,
	FONS_ALIGN_MIDDLE	= 1<<4,
	FONS_ALIGN_BOTTOM	= 1<<5,
	FONS_ALIGN_BASELINE	= 1<<6, // Default
};

enum FONSerrorCode {
	// Font atlas is full.
	FONS_ATLAS_FULL = 1,
	// Scratch memory used to render glyphs is full, requested size reported in 'val', you may need to bump up FONS_SCRATCH_BUF_SIZE.
	FONS_SCRATCH_FULL = 2,
	// Calls to fonsPushState has created too large stack, if you need deep state stack bump up FONS_MAX_STATES.
	FONS_STATES_OVERFLOW = 3,
	// Trying to pop too many states fonsPopState().
	FONS_STATES_UNDERFLOW = 4,
};

struct FONSparams {
	int width, height;
	unsigned char flags;
	void* userPtr;
	int (*renderCreate)(void* uptr, int width, int height);
	int (*renderResize)(void* uptr, int width, int height);
	void (*renderUpdate)(void* uptr, int* rect, const unsigned char* data);
	void (*renderDraw)(void* uptr, const float* verts, const float* tcoords, const unsigned int* colors, int nverts);
	void (*renderDelete)(void* uptr);
};
typedef struct FONSparams FONSparams;

struct FONSquad
{
	float x0,y0,s0,t0;
	float x1,y1,s1,t1;
};
typedef struct FONSquad FONSquad;

struct FONStextIter {
	float x, y, nextx, nexty, scale, spacing;
	unsigned int codepoint;
	short isize, iblur;
	struct FONSfont* font;
	int prevGlyphIndex;
	const char* str;
	const char* next;
	const char* end;
	unsigned int utf8state;
};
typedef struct FONStextIter FONStextIter;

typedef struct FONScontext FONScontext;

// Contructor and destructor.
FONS_DEF_API FONScontext* fonsCreateInternal(FONSparams* params);
FONS_DEF_API void fonsDeleteInternal(FONScontext* s);

FONS_DEF_API void fonsSetErrorCallback(FONScontext* s, void (*callback)(void* uptr, int error, int val), void* uptr);
// Returns current atlas size.
FONS_DEF_API void fonsGetAtlasSize(FONScontext* s, int* width, int* height);
// Expands the atlas size. 
FONS_DEF_API int fonsExpandAtlas(FONScontext* s, int width, int height);
// Resets the whole stash.
FONS_DEF_API int fonsResetAtlas(FONScontext* stash, int width, int height);

// Add fonts
FONS_DEF_API int fonsAddFont(FONScontext* s, const char* name, const char* path);
FONS_DEF_API int fonsAddFontMem(FONScontext* s, const char* name, unsigned char* data, int ndata, int freeData);
FONS_DEF_API int fonsGetFontByName(FONScontext* s, const char* name);
FONS_DEF_API int fonsAddFallbackFont(FONScontext* stash, int base, int fallback);

// State handling
FONS_DEF_API void fonsPushState(FONScontext* s);
FONS_DEF_API void fonsPopState(FONScontext* s);
FONS_DEF_API void fonsClearState(FONScontext* s);

// State setting
FONS_DEF_API void fonsSetSize(FONScontext* s, float size);
FONS_DEF_API void fonsSetColor(FONScontext* s, unsigned int color);
FONS_DEF_API void fonsSetSpacing(FONScontext* s, float spacing);
FONS_DEF_API void fonsSetBlur(FONScontext* s, float blur);
FONS_DEF_API void fonsSetAlign(FONScontext* s, int align);
FONS_DEF_API void fonsSetFont(FONScontext* s, int font);

// Draw text
FONS_DEF_API float fonsDrawText(FONScontext* s, float x, float y, const char* string, const char* end);

// Measure text
FONS_DEF_API float fonsTextBounds(FONScontext* s, float x, float y, const char* string, const char* end, float* bounds);
FONS_DEF_API void fonsLineBounds(FONScontext* s, float y, float* miny, float* maxy);
FONS_DEF_API void fonsVertMetrics(FONScontext* s, float* ascender, float* descender, float* lineh);

// Text iterator
FONS_DEF_API int fonsTextIterInit(FONScontext* stash, FONStextIter* iter, float x, float y, const char* str, const char* end);
FONS_DEF_API int fonsTextIterNext(FONScontext* stash, FONStextIter* iter, struct FONSquad* quad);

// Pull texture changes
FONS_DEF_API const unsigned char* fonsGetTextureData(FONScontext* stash, int* width, int* height);
FONS_DEF_API int fonsValidateTexture(FONScontext* s, int* dirty);

// Draws the stash texture for debugging
FONS_DEF_API void fonsDrawDebug(FONScontext* s, float x, float y);
