//
//  SecondPage.swift
//  Homework.To_Do
//
//  Created by 額賀力 on 2024/09/17.
//

import SwiftUI

struct SecondPage: View {
    @State var taskdata = [(title: "1", completed: false),
                           (title: "2", completed: false),
                           (title: "3", completed: false),
                           (title: "4", completed: false)]
    var body: some View {
        NavigationStack {
            List(0..<taskdata.count, id: \.self) { index in
                
                Button{
                    taskdata[index].completed.toggle()
                }label: {
                    HStack {
                        if taskdata[index].completed == true{
                            Image(systemName: "checkmark.circle.fill")
                        }else{
                            Image(systemName: "circle")
                        }
                        
                        Text(taskdata[index].title)
                    }
                }
                .foregroundColor(.primary)
                
            }
            .navigationTitle("今日やること")
        }
    }
}

#Preview {
    SecondPage()
        .modelContainer(for: Item.self, inMemory: true)
}
