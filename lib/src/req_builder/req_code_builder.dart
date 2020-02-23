import "package:built_collection/built_collection.dart";
import "package:code_builder/code_builder.dart";
import "package:gql/ast.dart";
import "package:gql_code_builder/source.dart";

Library buildReqLibrary(
  SourceNode docSource,
  String opDocUrl,
  String varDocUrl,
  String dataDocUrl,
) =>
    Library(
      (b) => b.body
        ..addAll(
          _buildOperationReqClasses(
            docSource.flatDocument,
            opDocUrl,
            varDocUrl,
            dataDocUrl,
          ),
        ),
    );

List<Class> _buildOperationReqClasses(
  DocumentNode doc,
  String opDocUrl,
  String varDocUrl,
  String dataDocUrl,
) =>
    doc.definitions
        .whereType<OperationDefinitionNode>()
        .map(
          (op) => _buildOperationReqClass(op, opDocUrl, varDocUrl, dataDocUrl),
        )
        .toList();

Class _buildOperationReqClass(
  OperationDefinitionNode node,
  String opDocUrl,
  String varDocUrl,
  String dataDocUrl,
) {
  final name = node.name.value;
  final varBuilderRef = refer("${name}VarBuilder", varDocUrl);
  final dataTypeRef = refer("\$${node.name.value}", dataDocUrl);
  final gqlClientUrl = "package:ferry/ferry.dart";

  return Class(
    (b) => b
      ..name = name
      ..extend = TypeReference((b) => b
        ..symbol = "QueryRequest"
        ..url = gqlClientUrl
        ..types.add(dataTypeRef))
      ..constructors = ListBuilder<Constructor>(
        <Constructor>[
          Constructor(
            (b) => b
              ..optionalParameters = ListBuilder<Parameter>(
                <Parameter>[
                  Parameter(
                    (b) => b
                      ..named = true
                      ..name = "buildVars"
                      ..type = FunctionType(
                        (b) => b
                          ..returnType = varBuilderRef
                          ..requiredParameters = ListBuilder<Reference>(
                            <Reference>[
                              varBuilderRef,
                            ],
                          ),
                      ),
                  ),
                  Parameter(
                    (b) => b
                      ..named = true
                      ..name = "queryId"
                      ..type = refer("String"),
                  ),
                  Parameter(
                    (b) => b
                      ..named = true
                      ..name = "updateResult"
                      ..type = FunctionType((b) => b
                        ..returnType = dataTypeRef
                        ..requiredParameters = ListBuilder<Reference>(
                            <Reference>[dataTypeRef, dataTypeRef])),
                  ),
                  Parameter(
                    (b) => b
                      ..named = true
                      ..name = "optimisticResponse"
                      ..type = refer("Map<String, dynamic>"),
                  ),
                  Parameter((b) => b
                    ..named = true
                    ..name = "updateCacheHandlerKey"),
                  Parameter(
                    (b) => b
                      ..named = true
                      ..name = "context"
                      ..type = refer("Map<String, dynamic>"),
                  ),
                  Parameter(
                    (b) => b
                      ..named = true
                      ..name = "fetchPolicy"
                      ..type = refer("FetchPolicy", gqlClientUrl),
                  ),
                ],
              )
              ..initializers = ListBuilder<Code>(
                <Code>[
                  refer(
                    "super",
                  ).call(
                    [],
                    {
                      "operation": refer(
                        name,
                        opDocUrl,
                      ),
                      "variables": refer("buildVars")
                          .notEqualTo(refer('null'))
                          .conditional(
                              refer("buildVars").call(
                                <Expression>[
                                  varBuilderRef.call([]),
                                ],
                              ).property("variables"),
                              refer('{}')),
                      "queryId": refer("queryId").notEqualTo(refer('null')
                          .conditional(
                              refer("queryId"),
                              refer("Uuid", "package:uuid/uuid.dart")
                                  .call([])
                                  .property("v4")
                                  .call([]))),
                      "updateResult": refer("updateResult"),
                      "optimisticResponse": refer("optimisticResponse"),
                      "updateCacheHandlerKey": refer("updateCacheHandlerKey"),
                      "context": refer("context"),
                      "fetchPolicy": refer("fetchPolicy"),
                    },
                  ).code,
                ],
              ),
          ),
        ],
      )
      ..methods = ListBuilder<Method>(<Method>[_buildParse(node, dataDocUrl)]),
  );
}

Method _buildParse(OperationDefinitionNode node, String dataDocUrl) =>
    Method((b) => b
      ..returns = refer("\$${node.name.value}", dataDocUrl)
      ..name = "parseData"
      ..requiredParameters.add(Parameter((b) => b
        ..type = refer("Map<String, dynamic>")
        ..name = "json"))
      ..lambda = true
      ..body =
          refer("\$${node.name.value}", dataDocUrl).call([refer("json")]).code);
