//
//  AddMemberView.swift
//  App
//
//  Created by joker on 2025-01-16.
//

import SwiftUI
import SwiftData

struct PeopleView: View {
    @EnvironmentObject var ipcViewModel: IPCViewModel
    @State private var searchText = ""
    @State private var newMemberID: String = ""
    @State private var showingAddMemberAlert = false
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \People.name) private var people: [People]
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(people, id: \.id) { member in
                        Text(member.name ?? "")
                    }
                    .onDelete(perform: deleteMember)
                }
                .searchable(text: $searchText)
                Spacer()
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem {
                    Button {
                        showingAddMemberAlert.toggle()
                    } label: {
                        Label("Add People", systemImage: "plus")
                    }
                }
            }
            .alert("Add People", isPresented: $showingAddMemberAlert) {
                TextField("Enter ID", text: $newMemberID)
                    .padding()
                Button("Save") {
                    addPeerToSwarm()
                    createNewMember()
                    showingAddMemberAlert.toggle()
                }
                .disabled(newMemberID.isEmpty)
                
                Button("Cancel", role: .cancel) {
                    showingAddMemberAlert.toggle()
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    
    private func addPeerToSwarm() {
        Task {
            let message: [String: Any] = [
                "action": "joinPeer",
                "data": self.newMemberID
            ]
            
            await ipcViewModel.writeToIPC(message: message)
            self.newMemberID = ""
        }
    }
   
    
    private func createNewMember() {
        let newMember = People(id: newMemberID)
        modelContext.insert(newMember)
        try? modelContext.save()
    }
    
    private func deleteMember(at offsets: IndexSet) {
        for index in offsets {
            let member = people[index]
            modelContext.delete(member)
            try? modelContext.save()
        }
    }
}

#Preview {
    PeopleView()
        .environmentObject(IPCViewModel())
}
