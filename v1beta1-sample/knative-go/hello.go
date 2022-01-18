package hello

import (
    "fmt"
    "net/http"
)

func HelloWorld(w http.ResponseWriter, r *http.Request) error {
    fmt.Fprint(w, "Hello, World!\n")
    return nil
}