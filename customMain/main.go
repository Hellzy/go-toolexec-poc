package main

import "fmt"
import "gopkg.in/DataDog/dd-trace-go.v1/internal/appsec"

func main() {
    appsec.Start()
    fmt.Println("hello")
}
