package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"log/slog"
	"net/http"
)

var s3Client *s3.Client

func main() {
	ctx := context.Background()

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		slog.Error("unable to load SDK config", "error", err)
		return
	}

	s3Client = s3.NewFromConfig(cfg)

	http.HandleFunc("/", listBuckets)

	slog.Info("server running on port 8080 ...")

	err = http.ListenAndServe(":8080", nil)
	if err != nil {
		slog.Error("error during listen and serve on port 8080", "error", err.Error())
	}
}

func listBuckets(w http.ResponseWriter, r *http.Request) {
	result, err := s3Client.ListBuckets(r.Context(), &s3.ListBucketsInput{})
	if err != nil {
		slog.Error("unable to list buckets", "error", err.Error())
		http.Error(w, "unable to list buckets", http.StatusInternalServerError)
		return
	}

	for _, bucket := range result.Buckets {
		fmt.Fprintln(w, *bucket.Name)
	}
}
