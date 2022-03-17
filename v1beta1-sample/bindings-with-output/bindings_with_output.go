package bindings

import (
	"encoding/json"

	ofctx "github.com/OpenFunction/functions-framework-go/context"
	"k8s.io/klog/v2"
)

func BindingsOutput(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
	var greeting []byte
	if in != nil {
		klog.Infof("binding - Data: %s", in)
		greeting = in
	} else {
		klog.Infof("binding - Data: Received")
		greeting, _ = json.Marshal(map[string]string{"message": "Hello"})
	}

	_, err := ctx.Send("sample", greeting)
	if err != nil {
		klog.Infof("Error: %v\n", err)
		return ctx.ReturnOnInternalError(), err
	}
	return ctx.ReturnOnSuccess(), nil
}
