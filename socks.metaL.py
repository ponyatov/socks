## @file
## @brief meta: Secure Open Cluster microKernel OS

from metaL import *

p = Project(
    title='''Secure Open Cluster microKernel OS''',
    about='''
* Rust microkernel for x86 (QEMU-i386)
* Erlang reworked runtime
''') \
    | Rust()

p.sync()
