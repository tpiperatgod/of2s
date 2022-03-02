package userfunction

import (
    "encoding/json"
    "k8s.io/klog/v2"

    ofctx "main.go/context"
)

func Sender(ctx ofctx.Context, in []byte) (ofctx.Out, error) {
    msg := map[string]string{
        "hello": "world",
    }

    msgBytes, _ := json.Marshal(msg)

    res, err := ctx.Send("target", msgBytes)
    if err != nil {
        klog.Error(err)
        return ctx.ReturnOnInternalError(), err
    }
    klog.Infof("send msg and receive result: %s", string(res))

    return ctx.ReturnOnSuccess(), nil
}