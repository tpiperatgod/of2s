package userfunction

import (
    "encoding/json"
    "k8s.io/klog/v2"
    ofctx "main.go/context"
)

func Producer(ctx ofctx.Context, in []byte) (ofctx.Out, error) {

    msg := map[string]string{
        "hello": "world",
    }

    msgBytes, _ := json.Marshal(msg)

    res, err := ctx.Send("pub", msgBytes)
    if err != nil {
        return ctx.ReturnOnInternalError(), err
    }
    klog.Infof("send msg and receive result: %s", string(res))

    return ctx.ReturnOnSuccess(), nil
}