package sender

import (
	"encoding/json"

	ofctx "github.com/OpenFunction/functions-framework-go/context"
	"k8s.io/klog/v2"
)

func Sender(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
	var greeting []byte
	if in != nil {
		klog.Infof("http - Data: %s", in)
		greeting = in
	} else {
		klog.Infof("http - Data: Received")
		greeting, _ = json.Marshal(map[string]string{"message": "Hello"})
	}

	_, err := ctx.Send("target", greeting)
	if err != nil {
		klog.Infof(err.Error())
		return ctx.ReturnOnInternalError(), err
	}

	return ctx.ReturnOnSuccess(), nil
}
