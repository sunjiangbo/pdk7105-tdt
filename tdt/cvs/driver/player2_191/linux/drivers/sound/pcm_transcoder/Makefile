CCFLAGSY += -I$(DRIVER_TOPDIR)/include/player2

# workaround for stlinux24
ifneq (,$(findstring 2.6.3,$(KERNELVERSION)))
ccflags-y += $(CCFLAGSY)
endif

pcm_transcoder-objs:= pcm_transcoder_module.o pcm_transcoder_transformer.o

obj-$(CONFIG_STM_UNIFY_PCM_TRANSCODER) += pcm_transcoder.o
