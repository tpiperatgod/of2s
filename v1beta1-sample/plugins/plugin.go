package bindings

import (
	ofctx "github.com/OpenFunction/functions-framework-go/context"
	"k8s.io/klog/v2"
)

func HandleCronInput(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
	if in != nil {
		klog.Infof("binding - Data: %s", in)
	} else {
		klog.Infoln("binding - Data: Received")
	}
	return ctx.ReturnOnSuccess(), nil
}
