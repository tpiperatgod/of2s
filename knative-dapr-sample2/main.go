package main

import (
	"context"
	"fmt"
	dapr "github.com/dapr/go-sdk/client"
	"io"
	"log"
	"net/http"
	"os"
)

var targetComponent string

func handler(w http.ResponseWriter, r *http.Request) {
	log.Print("helloworld: received a request")
	target := os.Getenv("TARGET")
	if target == "" {
		target = "World"
	}
	fmt.Fprintf(w, "Hello %s!\n", target)

	body, err := io.ReadAll(r.Body)
	log.Printf("receive: %s", string(body))

	client, err := dapr.NewClientWithPort("50001")
	if err != nil {
		fmt.Fprintf(w, "Cannot create dapr client %s!\n", err.Error())
		log.Fatal(err)
	}

	in := &dapr.InvokeBindingRequest{
		Name: targetComponent,
		Operation: "create",
		Data: body,
		Metadata: map[string]string{},
	}
	err = client.InvokeOutputBinding(context.Background(), in)
	if err != nil {
		fmt.Fprintf(w, "Cannot create dapr client %s!\n", err.Error())
		log.Fatal(err)
	}
}

func main() {
	log.Print("helloworld: starting server...")

	http.HandleFunc("/", handler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	targetComponent = os.Getenv("COMPONENT")
	if targetComponent == "" {
		log.Fatal("COMPONENT is empty")
	}

	log.Printf("helloworld: listening on port %s", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}