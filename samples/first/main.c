#include <stdio.h>

#include <CMSDK_CM3.h>
#include <board.h>
#include <device.h>
#include <logging.h>
LOG_MODULE_REGISTER(app_net, LOG_LEVEL_DBG);

int _write(int fd, char *buf, int count)
{
	for (; count != 0; --count) {
		serial_poll_out(serial_console, *buf++);
	}
	return count;
}

int main(void)
{
	serial_init(serial_console);

	for (;;) {
		LOG_INF("Hello World!");
	}
}