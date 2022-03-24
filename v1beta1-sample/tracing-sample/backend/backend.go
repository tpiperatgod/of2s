package bindings

import (
	"encoding/json"

	ofctx "github.com/OpenFunction/functions-framework-go/context"
	"k8s.io/klog/v2"
)

func HandleKafkaInput(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
	var msg Message
	err := json.Unmarshal(in, &msg)
	if err != nil {
		klog.Errorf("error reading message from Kafka binding", err)
		return ctx.ReturnOnInternalError(), err
	}
	klog.Infof("message from Kafka '%s'\n", msg)
	return ctx.ReturnOnSuccess(), nil
}

type Message struct {
	Msg string `json:"message"`
}
