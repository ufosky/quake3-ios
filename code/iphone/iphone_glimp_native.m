/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, February 2008.
 */

#include "iphone_local.h"
#include "iphone_glimp.h"
#include "tr_local.h"
#import	"Q3Application.h"
#import	"Q3ScreenView.h"

#import	<OpenGLES/egl.h>

static EGLDisplay eglDisplay;
static EGLContext eglContext;
static EGLSurface eglSurface;
static CoreSurfaceBufferRef coreSurface;

#ifdef QGL_CHECK_GL_ERRORS
void
QGLErrorBreak(void)
{
}
#endif // QGL_CHECK_GL_ERRORS

void
GLimp_SetMode(void)
{
	EGLint major, minor;
	EGLint eglAttrs[] =
	{
		EGL_BUFFER_SIZE, IPHONE_BPP,
		EGL_DEPTH_SIZE, IPHONE_DEPTH_BPP,
		EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
		EGL_NONE
	};
	EGLConfig eglConfig;
	EGLint numConfigs;
	EGLint eglConfigID;

	eglDisplay = eglGetDisplay(0);

	if (!eglInitialize(eglDisplay, &major, &minor))
		ri.Error(ERR_FATAL, "Could not initialize EGL (error = %d)\n", eglGetError());
	ri.Printf(PRINT_ALL, "  Using OpenGL ES version %d.%d\n", major, minor);

	if (!eglChooseConfig(eglDisplay, eglAttrs, &eglConfig, 1, &numConfigs))
		ri.Error(ERR_FATAL, "Could not find appropriate EGL config (error = %d)\n", eglGetError());
	eglGetConfigAttrib(eglDisplay, eglConfig, EGL_CONFIG_ID, &eglConfigID);
	ri.Printf(PRINT_ALL, "  EGL_CONFIG_ID = %d\n", eglConfigID);

	if ((eglContext = eglCreateContext(eglDisplay, eglConfig, EGL_NO_CONTEXT, 0)) == EGL_NO_CONTEXT)
		ri.Printf(PRINT_ALL, "Failed to allocate EGL context (error = %d)\n", eglGetError());

	coreSurface = [[(Q3Application *)UIApp screenView] surface];
	if ((eglSurface = eglCreatePixmapSurface(eglDisplay, eglConfig, coreSurface, 0)) == EGL_NO_SURFACE)
		ri.Error(ERR_FATAL, "Could not create EGL surface (error = %d)\n", eglGetError());

	if (!eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext))
		ri.Error(ERR_FATAL, "GLimp_Init: Could not make EGL context current (error = %d)\n", eglGetError());
}

void
GLimp_AcquireGL(void)
{
	eglWaitNative(EGL_CORE_NATIVE_ENGINE);
	CoreSurfaceBufferLock(coreSurface, 3);
	if (!eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext))
		ri.Error(ERR_FATAL, "GLimp_BeginFrame: Could not make EGL context current (error = %d)\n", eglGetError());
}

void
GLimp_ReleaseGL(void)
{
    eglWaitGL();
    eglMakeCurrent(eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
	CoreSurfaceBufferUnlock(coreSurface);
}

void
GLimp_EndFrame(void)
{
	GLimp_ReleaseGL();
	[[(Q3Application *)UIApp screenView]
			performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

void
GLimp_Shutdown(void)
{
	ri.Printf(PRINT_ALL, "Shutting down EGL.\n");

	eglMakeCurrent(eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
	eglTerminate(eglDisplay);
}