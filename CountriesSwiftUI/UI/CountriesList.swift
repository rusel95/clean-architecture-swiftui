//
//  CountriesList.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 24.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct CountriesList: View {
    @ObservedObject var viewModel: ViewModel
    @State var selectedCounrtyCode: Country.Code?
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationBarTitle("Countries")
        }
    }
    
    // MARK: - Views
    
    private var content: AnyView {
        switch viewModel.content {
        case .notRequested: return AnyView(notRequestedView)
        case let .isLoading(last): return AnyView(loadingView(last))
        case let .loaded(countries): return AnyView(loadedView(countries))
        case let .failed(error): return AnyView(failedView(error))
        }
    }
    
    private var notRequestedView: some View {
        Text("").onAppear {
            self.viewModel.loadCountries()
        }
    }
    
    private func loadingView(_ previouslyLoaded: [Country]?) -> some View {
        VStack {
            Text("Loading...").padding()
            previouslyLoaded.map {
                loadedView($0)
            }
        }
    }
    
    private func loadedView(_ countries: [Country]) -> some View {
        List(countries) { country in
            NavigationLink(
                destination: CountryDetails(
                    viewModel: CountryDetails.ViewModel(
                        container: self.viewModel.container,
                        country: country)),
                tag: country.alpha3Code,
                selection: self.$selectedCounrtyCode) {
                    CountryCell(country: country)
                }
        }
    }
    
    private func failedView(_ error: Error) -> some View {
        ErrorView(error: error, retryAction: {
            self.viewModel.loadCountries()
        })
    }
}

extension CountriesList {
    class ViewModel: ContentViewModel<[Country]> {
        
        let container: DIContainer
        private var requestToken: Cancellable?
        
        init(container: DIContainer) {
            self.container = container
            super.init(publisher: container.appState.countries.eraseToAnyPublisher(), hasDataToDisplay: {
                    ($0.value?.count ?? 0) > 0
                })
        }
        
        func loadCountries() {
            requestToken?.cancel()
            requestToken = container.countriesService.loadCountries()
        }
    }
}

#if DEBUG

extension CountriesList.ViewModel {
    static var preview: CountriesList.ViewModel {
        return CountriesList.ViewModel(container:
            DIContainer(presetCountries: .loaded(Country.sampleData))
        )
    }
}

struct CountriesList_Previews: PreviewProvider {
    static var previews: some View {
        CountriesList(viewModel: CountriesList.ViewModel.preview)
    }
}
#endif
