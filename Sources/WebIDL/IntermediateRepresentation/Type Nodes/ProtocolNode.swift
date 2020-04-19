//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class ProtocolNode: TypeNode, Equatable {

    let typeName: String
    var inheritsFrom: Set<NodePointer>

    var requiredMembers: [MemberNode]
    var defaultImplementations: [MemberNode]

    internal init(typeName: String, inheritsFrom: Set<NodePointer>, requiredMembers: [MemberNode], defaultImplementations: [MemberNode]) {
        self.typeName = typeName
        self.inheritsFrom = inheritsFrom
        self.requiredMembers = requiredMembers
        self.defaultImplementations = defaultImplementations
    }

    var isProtocol: Bool {
        return true
    }

    var swiftTypeName: String {

        return typeName
    }

    var typeErasedSwiftType: String {
        return "TypeErased\(swiftTypeName)"
    }

    var swiftDeclaration: String {

        let (namedSubscript, indexedSubscript) = SubscriptNode.mergedSubscriptNodes(requiredMembers.filter({ $0.isSubscript }) as! [SubscriptNode])

        let inheritsFrom = ["JSBridgedType"] + self.inheritsFrom.map({ $0.node!.swiftTypeName }).sorted()
        var declaration =  """
        public protocol \(typeName): \(inheritsFrom.map({ $0 }).joined(separator: ", ")) {

        """

        declaration += "\n"
        namedSubscript.map { declaration += $0.swiftDeclarations(inContext: .protocolContext).joined(separator: "\n\n")}
        declaration += "\n"
        indexedSubscript.map { declaration += $0.swiftDeclarations(inContext: .protocolContext).joined(separator: "\n\n")}
        declaration += "\n"

        declaration += requiredMembers
            .filter({ !$0.isSubscript })
            .flatMap({
                return $0.swiftDeclarations(inContext: .protocolContext)
            })
            .joined(separator: "\n\n")

        declaration += "\n}"

        if !defaultImplementations.isEmpty {

            let (namedSubscript, indexedSubscript) = SubscriptNode.mergedSubscriptNodes(requiredMembers.filter({ $0.isSubscript }) as! [SubscriptNode])

            declaration += """


            public extension \(typeName) {


            """

            declaration += "\n"
            namedSubscript.map { declaration += $0.swiftImplementations(inContext: .protocolContext).joined(separator: "\n\n")}
            declaration += "\n"
            indexedSubscript.map { declaration += $0.swiftImplementations(inContext: .protocolContext).joined(separator: "\n\n")}
            declaration += "\n"

            declaration += defaultImplementations
                       .filter({ !$0.isSubscript })
                       .flatMap({
                           return $0.swiftImplementations(inContext: .protocolContext)
                       })
                       .joined(separator: "\n\n")

            declaration += "\n}"

        }

        return declaration
    }

    static func == (lhs: ProtocolNode, rhs: ProtocolNode) -> Bool {
        return lhs.typeName == rhs.typeName
    }
}
