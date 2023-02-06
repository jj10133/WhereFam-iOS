#include <pear.h>
#include <uv.h>

#include "app.js.h"

int
main (int argc, char *argv[]) {
  pear_t pear;
  pear_setup(uv_default_loop(), &pear, argc, argv);

  pear_run(&pear, "<main>", (char *) app_js, app_js_len);

  int exit_code;
  pear_teardown(&pear, &exit_code);

  return exit_code;
}
