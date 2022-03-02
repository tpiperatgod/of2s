package userfunction

import (
    "k8s.io/klog/v2"
    ofctx "main.go/context"
    "time"
)

func Producer(ctx ofctx.Context, in []byte) (ofctx.Out, error) {

    //msg := map[string]string{
    //    "hello": "world",
    //}

    //msgBytes, _ := json.Marshal(msg)

    res, err := ctx.Send("pub", []byte(time.Now().String()))
    if err != nil {
        return ctx.ReturnOnInternalError(), err
    }
    klog.Infof("send msg and receive result: %s", string(res))

    return ctx.ReturnOnSuccess(), nil
}