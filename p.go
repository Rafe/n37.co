package main

import (
  "fmt"
  "math"
)

func P(n float64, m float64) float64{
  return math.Exp( -math.Pow(n, 2) / (2 * m))
}

func main(){
  fmt.Println(1 - P(1355, 916132832))
}
