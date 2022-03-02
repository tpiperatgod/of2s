package userfunction

import (
    "log"

    ofctx "main.go/context"
)

func Target(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
    log.Printf("bindings - Data: %s", in)
    return ctx.ReturnOnSuccess(), nil
}