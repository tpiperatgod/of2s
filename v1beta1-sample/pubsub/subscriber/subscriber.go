package subscriber

import (
    ofctx "github.com/OpenFunction/functions-framework-go/context"
    "log"
)

func Subscriber(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
    log.Printf("event - Data: %s", in)
    return ctx.ReturnOnSuccess(), nil
}