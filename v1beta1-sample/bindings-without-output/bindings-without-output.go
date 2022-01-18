package bindings

import (
    ofctx "github.com/OpenFunction/functions-framework-go/context"
    "log"
)

func BindingsNoOutput(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
    if in != nil {
        log.Printf("binding - Data: %s", in)
    } else {
        log.Print("binding - Data: Received")
    }
    return ctx.ReturnOnSuccess(), nil
}