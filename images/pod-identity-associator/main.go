package main

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/eks"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"log/slog"
	"os"
)

var s3Client *s3.Client

func main() {
	ctx := context.Background()

	// Validate number of input arguments
	if len(os.Args) != 5 {
		slog.Error("Usage: pod-identity-associator <cluster-name> <namespace> <service-account> <role-arn>")
		os.Exit(1)
	}

	// Assign input arguments to variables
	clusterName := os.Args[1]
	namespace := os.Args[2]
	serviceAccount := os.Args[3]
	roleArn := os.Args[4]

	// Load AWS SDK config
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		slog.Error("unable to load SDK config", "error", err)
		return
	}

	// Create EKS client
	eksClient := eks.NewFromConfig(cfg)

	// List existing pod identity associations (if any)
	slog.Info(
		"listing pod identity associations",
		"clusterName", clusterName,
		"namespace", namespace,
		"serviceAccount", serviceAccount,
	)
	associations, err := eksClient.ListPodIdentityAssociations(ctx, &eks.ListPodIdentityAssociationsInput{
		ClusterName:    &clusterName,
		Namespace:      &namespace,
		ServiceAccount: &serviceAccount,
	})
	if err != nil {
		slog.Error(
			"unable to get pod identity associations",
			"error", err,
			"clusterName", clusterName,
			"namespace", namespace,
			"serviceAccount", serviceAccount,
			"roleArn", roleArn,
		)
		os.Exit(1)
	}

	// Convert associations to slice of ID strings
	associationIds := make([]string, 0)
	for _, association := range associations.Associations {
		associationIds = append(associationIds, *association.AssociationId)
	}
	slog.Info(
		"found pod identity associations",
		"clusterName", clusterName,
		"namespace", namespace,
		"serviceAccount", serviceAccount,
		"associationIds", associationIds,
	)

	// Validate if we have more than one association (which should not happen)
	if len(associationIds) > 1 {
		slog.Error(
			"multiple pod identity associations found",
			"clusterName", clusterName,
			"namespace", namespace,
			"serviceAccount", serviceAccount,
			"associationIds", associationIds,
		)
		os.Exit(1)
	} else
	// If we have only one association, we need to update it
	if len(associationIds) == 1 {
		slog.Info(
			"one pod identity association found, updating ...",
			"clusterName", clusterName,
			"namespace", namespace,
			"serviceAccount", serviceAccount,
		)
		association, err := eksClient.UpdatePodIdentityAssociation(ctx, &eks.UpdatePodIdentityAssociationInput{
			ClusterName:   &clusterName,
			AssociationId: &associationIds[0],
			RoleArn:       &roleArn,
		})
		if err != nil {
			slog.Error(
				"unable to update pod identity associations",
				"error", err,
				"clusterName", clusterName,
				"namespace", namespace,
				"serviceAccount", serviceAccount,
				"roleArn", roleArn,
			)
			os.Exit(1)
		}
		slog.Info(
			"pod identity association updated",
			"clusterName", clusterName,
			"namespace", namespace,
			"serviceAccount", serviceAccount,
			"roleArn", roleArn,
			"associationId", *association.Association.AssociationId,
		)
	} else
	// If we have no associations, we need to create it
	if len(associationIds) == 0 {
		slog.Info(
			"no pod identity association found, creating ...",
			"clusterName", clusterName,
			"namespace", namespace,
			"serviceAccount", serviceAccount,
			"roleArn", roleArn,
		)
		association, err := eksClient.CreatePodIdentityAssociation(ctx, &eks.CreatePodIdentityAssociationInput{
			ClusterName:    &clusterName,
			Namespace:      &namespace,
			ServiceAccount: &serviceAccount,
			RoleArn:        &roleArn,
		})
		if err != nil {
			slog.Error(
				"unable to create pod identity associations",
				"error", err,
				"clusterName", clusterName,
				"namespace", namespace,
				"serviceAccount", serviceAccount,
				"roleArn", roleArn,
			)
			os.Exit(1)
		}
		slog.Info(
			"pod identity association created",
			"clusterName", clusterName,
			"namespace", namespace,
			"serviceAccount", serviceAccount,
			"roleArn", roleArn,
			"associationId", *association.Association.AssociationId,
		)
	}
}
