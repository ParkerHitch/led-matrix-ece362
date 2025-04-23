.cpu cortex-m0
.thumb
.syntax unified

.type nano_wait, %function
.global nano_wait
nano_wait:
    subs   r0, #83
    bgt    nano_wait
    bx     lr
