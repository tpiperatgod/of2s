package bindings

import (
	"log"

	ofctx "github.com/tpiperatgod/offf-go/context"
)

func BindingsNoOutput(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
	if in != nil {
		log.Printf("binding - Data: %s", in)
	} else {
		log.Print("binding - Data: Received")
	}
	return ctx.ReturnOnSuccess(), nil
}
