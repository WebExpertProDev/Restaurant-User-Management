import React from "react";
import {
  List,
  Edit,
  SimpleForm,
  TextInput,
  NumberInput,
  BooleanInput,
  NumberField,
  Datagrid,
  UrlField,
  BooleanField,
  ImageField,
  TextField,
} from "react-admin";

export const RestaurantList = (props) => (
  <List {...props}>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <BooleanField source="is_hidden" label="Hidden" />
      <TextField source="name" />
      <ImageField
        source="details.images[0]"
        label="Picture"
        className="img"
        sortable={false}
      />
      <UrlField source="details.yelpPage" label="Yelp Listing" />
      <UrlField source="details.opentablePage" label="Opentable Listing" />
      <UrlField source="details.resyPage" label="Resy Listing" />
      <UrlField source="details.tockPage" label="Tock Listing" />
      <TextField source="latitude" />
      <TextField source="longitude" />
      <TextField source="cuisines" label="Cuisines" sortable={false} />
      <NumberField source="price_band" label="Price" />
      <TextField source="neighborhood" label="Neighborhood" />
      <TextField source="details.region" label="Region" />
    </Datagrid>
  </List>
);

export const RestaurantEdit = (props) => (
  <Edit {...props}>
    <SimpleForm>
      <TextInput disabled source="id" />
      <TextInput source="name" />
      <BooleanInput source="is_hidden" />
      <TextInput source="cuisines" label="Cuisines (comma delimit)" />
      <NumberInput
        source="price_band"
        label="Price"
        inputProps={{ min: 1, max: 4 }}
      />
      <TextInput source="neighborhood" />
    </SimpleForm>
  </Edit>
);

export default RestaurantList;
