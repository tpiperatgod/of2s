package demo

import (
    "fmt"
    ofctx "github.com/OpenFunction/functions-framework-go/openfunction-context"
)

func Demo(ctx *ofctx.OpenFunctionContext, in []byte) ofctx.RetValue {
    e := ctx.Event.TopicEvent
    fmt.Println("--*-- Event Information --*--")
    fmt.Println("ID: ", e.ID)
    fmt.Println("Data: ", e.Data)
    fmt.Println("Content Type: ", e.DataContentType)
    return ctx.ReturnWithSuccess()
}