#ifndef NOVA_XGE_COMPAT_H
#define NOVA_XGE_COMPAT_H

/*
 * The packaged libXi header includes Xge.h, while the matching xorgproto
 * package names this protocol-only header ge.h. Xlib supplies the generic
 * event cookie types used by XI2, so the compatibility include is sufficient
 * for this read-only diagnostic build.
 */
#include <X11/extensions/ge.h>

#endif
