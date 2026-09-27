//================ Copyright (c) 2020, PG, All rights reserved. =================//
//
// Purpose:		thread wrapper
//
// $NoKeywords: $thread $os
//===============================================================================//

#include "Thread.h"
#include "ConVar.h"
#include "Engine.h"

#include "HorizonThread.h"

#ifdef MCENGINE_FEATURE_MULTITHREADING

#ifdef MCENGINE_FEATURE_PTHREADS

#include <pthread.h>

// pthread implementation of Thread
class PosixThread : public BaseThread
{
public:
	PosixThread(McThread::START_ROUTINE start_routine, void *arg) : BaseThread()
	{
		m_thread = 0;

		const int ret = pthread_create(&m_thread, NULL, start_routine, arg);
		m_bReady = (ret == 0);

		if (ret != 0)
			debugLog("PosixThread Error: pthread_create() returned %i!\n", ret);
	}

	virtual ~PosixThread()
	{
		if (!m_bReady) return;

		m_bReady = false;

		pthread_join(m_thread, NULL);

		m_thread = 0;
	}

	bool isReady()
	{
		return m_bReady;
	}

private:
	pthread_t m_thread;

	bool m_bReady;
};

#endif

#ifdef _WIN32

#include <windows.h>

struct WinThreadRoutineArg {
	McThread::START_ROUTINE start_routine;
	void *arg;
};

DWORD WINAPI WinThreadRoutine(void *arg) {
	WinThreadRoutineArg *r = (WinThreadRoutineArg*)arg;
	r->start_routine(r->arg);
	return 0;
}

class WinThread : public BaseThread
{
public:
	WinThread(McThread::START_ROUTINE start_routine, void *arg) : BaseThread()
	{
		m_ra = new WinThreadRoutineArg{ start_routine, arg };
		m_handle = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)WinThreadRoutine, m_ra, 0, 0);
	}

	virtual ~WinThread()
	{
		WaitForSingleObject(m_handle, INFINITE);
		CloseHandle(m_handle);
		delete m_ra;
	}

	bool isReady()
	{
		return true;
	}

private:
	HANDLE m_handle;
	WinThreadRoutineArg *m_ra;
};

#endif /* _WIN32 */

#endif

ConVar debug_thread("debug_thread", false, FCVAR_NONE);

ConVar *McThread::debug = &debug_thread;

McThread::McThread(START_ROUTINE start_routine, void *arg)
{
	m_baseThread = NULL;

#ifdef MCENGINE_FEATURE_MULTITHREADING

#ifdef MCENGINE_FEATURE_PTHREADS

	m_baseThread = new PosixThread(start_routine, arg);

#elif defined(__SWITCH__)

	m_baseThread = new HorizonThread(start_routine, arg);

#else

	m_baseThread = new WinThread(start_routine, arg);

#endif

#endif
}

McThread::~McThread()
{
	SAFE_DELETE(m_baseThread);
}

bool McThread::isReady()
{
	return (m_baseThread != NULL && m_baseThread->isReady());
}
