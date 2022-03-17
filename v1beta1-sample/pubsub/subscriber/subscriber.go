package subscriber

import (
	ofctx "github.com/OpenFunction/functions-framework-go/context"
	"k8s.io/klog/v2"
)

func Subscriber(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
	klog.Infof("event - Data: %s", in)
	return ctx.ReturnOnSuccess(), nil
}
