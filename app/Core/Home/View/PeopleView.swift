//
//  AddMemberView.swift
//  App
//
//  Created by joker on 2025-01-16.
//

import SwiftUI

struct PeopleView: View {
    @EnvironmentObject var ipcViewModel: IPCViewModel
    @State private var searchText = ""
    @State private var newMemberID: String = ""
    @State private var showingAddMemberAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(ipcViewModel.people, id: \.id) { member in
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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
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
        .onAppear {
            ipcViewModel.refreshPeople()
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
    
    private func leavePeerFromSwarm(memberID: String) {
        Task {
            let message: [String: Any] = [
                "action": "leavePeer",
                "data": memberID
            ]
            
            await ipcViewModel.writeToIPC(message: message)
        }
    }
    
    
    private func createNewMember() {
        let newMember = People(id: newMemberID)
        SQLiteManager.shared.insertPerson(newMember)
        ipcViewModel.refreshPeople()
    }
    
    private func deleteMember(at offsets: IndexSet) {
        for index in offsets {
            let member = ipcViewModel.people[index]
            leavePeerFromSwarm(memberID: member.id)
            SQLiteManager.shared.deletePerson(id: member.id)
        }
        
        ipcViewModel.refreshPeople()
    }
}

#Preview {
    PeopleView()
        .environmentObject(IPCViewModel())
}
