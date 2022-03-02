package main

import (
    "context"
    "k8s.io/klog/v2"
    "main.go/examples/bindings/target/userfunction"
    "main.go/framework"
    "main.go/plugin"
)

func main() {
    ctx := context.Background()
    fwk, err := framework.NewFramework()
    if err != nil {
        klog.Exit(err)
    }
    fwk.RegisterPlugins(getLocalPlugins())
    if err := fwk.Register(ctx, userfunction.Target); err != nil {
        klog.Exit(err)
    }
    if err := fwk.Start(ctx); err != nil {
        klog.Exit(err)
    }
}

func getLocalPlugins() map[string]plugin.Plugin {
    localPlugins := map[string]plugin.Plugin{}

    if len(localPlugins) == 0 {
        return nil
    } else {
        return localPlugins
    }
}