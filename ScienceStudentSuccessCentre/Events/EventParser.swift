//
//  EventParser.swift
//  SSSCTemp
//
//  Created by Avery Vine on 2018-02-02.
//  Copyright © 2018 Avery Vine. All rights reserved.
//

import Foundation
import SwiftSoup
import Alamofire

class EventParser {
    
    private static var instance: EventParser! = nil
    
    private let baseURL = "http://sssc.carleton.ca"
    private let serverURL = "http://sssc-carleton-app-server.herokuapp.com/events";
    private let eventsURL = "/events"
    private var events = [Event]()
    private var observers = [EventObserver]()
    
    public func loadEvents() {
        events.removeAll()
        Alamofire.request(serverURL).responseData { (resData) -> Void in
            do {
                if resData.result.value == nil {
                    throw Exception.Error(type: ExceptionType.MalformedURLException, Message: "HTTP load failed for URL \(self.serverURL)")
                }
                let dataString: String! = String(data : resData.result.value!, encoding: String.Encoding.utf8)
                let data: Data = dataString.data(using: String.Encoding.utf8)!;
                
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                print("Received data:")
                print(json as Any)
                let jsonArray = json as? NSArray
                if (jsonArray != nil) {
                    for eventData in jsonArray! {
                        print(eventData)
                        let event = Event(eventData: eventData as! NSDictionary)
                        self.insertEvent(newEvent: event)
                    }
                    self.notify()
                } else {
                    print("Received improper JSON data")
                    self.notify()
                    self.alertUser()
                }
            } catch Exception.Error(let type, let message) {
                print("\(type): \(message)")
                self.notify()
                self.alertUser()
            } catch {
                print("Error")
                self.notify()
                self.alertUser()
            }
        }
    }
    
    private func insertEvent(newEvent: Event) {
        var appended = false
        for i in 0 ..< events.count {
            let event = events[i]
            if newEvent.getYear() < event.getYear() {
                events.insert(newEvent, at: i)
                appended = true
                break
            } else if newEvent.getYear() == event.getYear() {
                if newEvent.getMonth() < event.getMonth() {
                    events.insert(newEvent, at: i)
                    appended = true
                    break
                } else if newEvent.getMonth() == event.getMonth() {
                    if newEvent.getDay() < event.getDay() {
                        events.insert(newEvent, at: i)
                        appended = true
                        break
                    }
                }
            }
        }
        if !appended {
            events.append(newEvent)
        }
    }
    
    private func alertUser() {
        let alert = UIAlertController(title: "Something went wrong!", message: "Something went wrong when loading the SSSC's upcoming events! Please try again later. If the issue persists, contact the SSSC so we can fix the problem as soon as possible.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        for observer in observers {
            observer.presentAlert(alert: alert)
        }
    }
    
    private func notify() {
        for observer in observers {
            observer.update()
        }
    }
    
    public func attachObserver(observer: EventObserver) {
        observers.append(observer)
    }
    
    public func getEvents() -> [Event] {
        return events
    }
    
    public static func getInstance() -> EventParser {
        if (instance == nil) {
            instance = EventParser()
        }
        return instance
    }
    
}
