//
//  ContentView.swift
//  Pokedex
//
//  Created by Gabriel Neman Silva on 20/11/25.
//

import SwiftUI

struct TypeContainer: Codable {
    let type: PokemonType
}

struct PokemonType: Codable {
    let name: String
}

class Sprites: Codable {
    let front_default: String
}

struct Pokemon: Codable, Identifiable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeContainer]
    
    var selecionado: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sprites
        case types
    }
}

struct ContentView: View {
    @State private var todosPokemon: [Pokemon] = []
    
    var body: some View {
        NavigationView {
            PokedexGrid(todosPokemon: $todosPokemon)
                .onAppear {
                    if todosPokemon.isEmpty {
                        Task {
                            await fetchTodosPokemon()
                        }
                    }
                }
        }
    }
    
    func fetchTodosPokemon() async {
        for i in 1...151 {
            guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(i)") else {
                continue
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decodedPokemon = try JSONDecoder().decode(Pokemon.self, from: data)
                
                DispatchQueue.main.async {
                    todosPokemon.append(decodedPokemon)
                }
            } catch {
                print("Erro ao buscar Pokémon com id \(i): \(error.localizedDescription)")
            }
        }
    }
}

struct PokedexGrid: View {
    @Binding var todosPokemon: [Pokemon]
    
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                NavigationLink(destination: TiposPokemonTela(todosPokemon: todosPokemon)) {
                    Text("Estatísticas")
                        .font(.title2).bold()
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach($todosPokemon) { $pokemon in
                        PokemonBotao(pokemon: $pokemon)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.darkGray))
        .navigationBarHidden(true)
    }
}

struct TiposPokemonTela: View {
    let todosPokemon: [Pokemon]

    private let traducoes: [String: String] = [
        "normal": "Normal", "fire": "Fogo", "water": "Água", "grass": "Planta",
        "electric": "Elétrico", "ice": "Gelo", "fighting": "Lutador", "poison": "Venenoso",
        "ground": "Terrestre", "flying": "Voador", "psychic": "Psíquico", "bug": "Inseto",
        "rock": "Pedra", "ghost": "Fantasma", "dragon": "Dragão", "dark": "Noturno",
        "steel": "Aço", "fairy": "Fada"
    ]
    
    private var pokemonsSelecionados: [Pokemon] {
        todosPokemon.filter { $0.selecionado }
    }
    
    private var totalTiposPokedex: [String: Int] {
        var counts: [String: Int] = [:]
        for pokemon in todosPokemon {
            for typeContainer in pokemon.types {
                let nomeTraduzido = traducoes[typeContainer.type.name] ?? typeContainer.type.name
                counts[nomeTraduzido, default: 0] += 1
            }
        }
        return counts
    }
    
    private var totalTiposSelecionados: [String: Int] {
        var counts: [String: Int] = [:]
        for pokemon in pokemonsSelecionados {
            for typeContainer in pokemon.types {
                let nomeTraduzido = traducoes[typeContainer.type.name] ?? typeContainer.type.name
                counts[nomeTraduzido, default: 0] += 1
            }
        }
        return counts
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    Text("Pokemons Pegos")
                        .font(.largeTitle).bold()
                    Text("\(pokemonsSelecionados.count)/151")
                        .font(.system(size: 36, weight: .bold))
                }
                .foregroundColor(.white)

                TiposPokemon(titulo: "Total na Pokédex", contagemTipos: totalTiposPokedex, traducoes: traducoes)

                TiposPokemon(titulo: "Tipos dos Selecionados", contagemTipos: totalTiposSelecionados, traducoes: traducoes)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.darkGray))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BotaoVoltar()
            }
        }
    }
}

struct PokemonBotao: View {
    @Binding var pokemon: Pokemon
    
    var body: some View {
        Button(action: {
            pokemon.selecionado.toggle()
        }) {
            VStack {
                AsyncImage(url: URL(string: pokemon.sprites.front_default)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 80)
                
                Text(pokemon.name.capitalized)
                    .font(.title3).bold()
                    .foregroundColor(.black)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 130)
            .background(pokemon.selecionado ? Color.green : Color.white)
            .cornerRadius(20)
            .shadow(radius: 5)
        }
    }
}

struct TiposPokemon: View {
    let titulo: String
    let contagemTipos: [String: Int]
    let traducoes: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.title).bold().padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .center)
            
            ForEach(traducoes.values.sorted(), id: \.self) { tipoTraduzido in
                HStack {
                    Text("\(tipoTraduzido):")
                    Spacer()
                    Text("\(contagemTipos[tipoTraduzido] ?? 0)")
                }
                .font(.body).bold()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.gray))
        .cornerRadius(20)
        .foregroundColor(.white)
    }
}

struct BotaoVoltar: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.backward")
                Text("Voltar")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
